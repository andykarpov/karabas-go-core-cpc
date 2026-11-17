module sna_save_capture (
	clk,
	reset,
	save_req,
	admit,
	rampage_ok,
	release_req,
	insn_start,
	halt_n,
	cpu_reg,
	hw_hdr,
	hold,
	captured,
	refused,
	cancelled,
	busy,
	header
);
	input clk;
	input reset;
	input save_req;
	input admit;
	input rampage_ok;
	input release_req;
	input insn_start;
	input halt_n;
	input [211:0] cpu_reg;
	input [1079:0] hw_hdr;
	output reg hold;
	output reg captured;
	output reg refused;
	output reg cancelled;
	output wire busy;
	output reg [2047:0] header;
	localparam [1:0] S_IDLE = 2'd0;
	localparam [1:0] S_ARMED = 2'd1;
	localparam [1:0] S_HELD = 2'd2;
	reg [1:0] state;
	reg insn_start_d;
	wire insn_start_rising = insn_start && !insn_start_d;
	assign busy = state != S_IDLE;
	wire [15:0] pc_raw = cpu_reg[79:64];
	wire [15:0] pc_adj = (halt_n ? pc_raw : pc_raw - 16'd1);
	wire [7:0] r_raw = cpu_reg[47:40];
	wire [7:0] r_adj = (halt_n ? r_raw : {r_raw[7], r_raw[6:0] - 7'd1});
	reg [2047:0] assembled_header;
	integer i;
	always @(*) begin
		assembled_header = {2048 {1'b0}};
		assembled_header[0+:8] = 8'h4d;
		assembled_header[8+:8] = 8'h56;
		assembled_header[16+:8] = 8'h20;
		assembled_header[24+:8] = 8'h2d;
		assembled_header[32+:8] = 8'h20;
		assembled_header[40+:8] = 8'h53;
		assembled_header[48+:8] = 8'h4e;
		assembled_header[56+:8] = 8'h41;
		assembled_header[128+:8] = 8'h03;
		assembled_header[136+:8] = cpu_reg[15:8];
		assembled_header[144+:8] = cpu_reg[7:0];
		assembled_header[152+:8] = cpu_reg[87:80];
		assembled_header[160+:8] = cpu_reg[95:88];
		assembled_header[168+:8] = cpu_reg[103:96];
		assembled_header[176+:8] = cpu_reg[111:104];
		assembled_header[184+:8] = cpu_reg[119:112];
		assembled_header[192+:8] = cpu_reg[127:120];
		assembled_header[200+:8] = r_adj;
		assembled_header[208+:8] = cpu_reg[39:32];
		assembled_header[216+:8] = {7'b0000000, cpu_reg[210]};
		assembled_header[224+:8] = {7'b0000000, cpu_reg[211]};
		assembled_header[232+:8] = cpu_reg[135:128];
		assembled_header[240+:8] = cpu_reg[143:136];
		assembled_header[248+:8] = cpu_reg[199:192];
		assembled_header[256+:8] = cpu_reg[207:200];
		assembled_header[264+:8] = cpu_reg[55:48];
		assembled_header[272+:8] = cpu_reg[63:56];
		assembled_header[280+:8] = pc_adj[7:0];
		assembled_header[288+:8] = pc_adj[15:8];
		assembled_header[296+:8] = {6'b000000, cpu_reg[209:208]};
		assembled_header[304+:8] = cpu_reg[31:24];
		assembled_header[312+:8] = cpu_reg[23:16];
		assembled_header[320+:8] = cpu_reg[151:144];
		assembled_header[328+:8] = cpu_reg[159:152];
		assembled_header[336+:8] = cpu_reg[167:160];
		assembled_header[344+:8] = cpu_reg[175:168];
		assembled_header[352+:8] = cpu_reg[183:176];
		assembled_header[360+:8] = cpu_reg[191:184];
		for (i = 0; i < 135; i = i + 1)
			assembled_header[(32'h0000002e + i) * 8+:8] = hw_hdr[i * 8+:8];
	end
	always @(posedge clk) begin
		insn_start_d <= insn_start;
		if (reset) begin
			state <= S_IDLE;
			hold <= 1'b0;
			captured <= 1'b0;
			refused <= 1'b0;
			cancelled <= 1'b0;
			header <= {2048 {1'b0}};
			insn_start_d <= 1'b0;
		end
		else begin
			captured <= 1'b0;
			refused <= 1'b0;
			cancelled <= 1'b0;
			case (state)
				S_IDLE:
					if (save_req) begin
						if (!admit || !rampage_ok)
							refused <= 1'b1;
						else
							state <= S_ARMED;
					end
				S_ARMED:
					if (!admit || save_req) begin
						cancelled <= 1'b1;
						state <= S_IDLE;
					end
					else if (insn_start_rising && !rampage_ok) begin
						refused <= 1'b1;
						state <= S_IDLE;
					end
					else if (insn_start_rising) begin
						hold <= 1'b1;
						captured <= 1'b1;
						header <= assembled_header;
						state <= S_HELD;
					end
				S_HELD:
					if (release_req) begin
						hold <= 1'b0;
						state <= S_IDLE;
					end
				default: begin
					state <= S_IDLE;
					hold <= 1'b0;
				end
			endcase
		end
	end
	initial begin
		state = S_IDLE;
		hold = 1'b0;
		captured = 1'b0;
		refused = 1'b0;
		cancelled = 1'b0;
		header = {2048 {1'b0}};
		insn_start_d = 1'b0;
	end
endmodule
