`default_nettype wire
module YM2149 (
	CLK,
	CE,
	RESET,
	BDIR,
	BC,
	DI,
	DO,
	CHANNEL_A,
	CHANNEL_B,
	CHANNEL_C,
	SEL,
	MODE,
	ACTIVE,
	IOA_in,
	IOA_out,
	IOB_in,
	IOB_out,
	SNA_LOAD,
	SNA_ADDR,
	SNA_REGS,
	SNAP_ADDR,
	SNAP_REGS
);
	reg _sv2v_0;
	input CLK;
	input CE;
	input RESET;
	input BDIR;
	input BC;
	input [7:0] DI;
	output wire [7:0] DO;
	output wire [7:0] CHANNEL_A;
	output wire [7:0] CHANNEL_B;
	output wire [7:0] CHANNEL_C;
	input SEL;
	input MODE;
	output wire [5:0] ACTIVE;
	input [7:0] IOA_in;
	output wire [7:0] IOA_out;
	input [7:0] IOB_in;
	output wire [7:0] IOB_out;
	input SNA_LOAD;
	input [3:0] SNA_ADDR;
	input [127:0] SNA_REGS;
	output wire [7:0] SNAP_ADDR;
	output wire [127:0] SNAP_REGS;
	reg [127:0] ymreg;
	assign ACTIVE = ~ymreg[69-:6];
	assign IOA_out = ymreg[8+:8];
	assign IOB_out = ymreg[0+:8];
	reg [7:0] addr;
	assign SNAP_ADDR = addr;
	genvar _gv_ymi_1;
	generate
		for (_gv_ymi_1 = 0; _gv_ymi_1 < 16; _gv_ymi_1 = _gv_ymi_1 + 1) begin : gen_snap_ymreg
			localparam ymi = _gv_ymi_1;
			assign SNAP_REGS[ymi * 8+:8] = ymreg[(15 - ymi) * 8+:8];
		end
	endgenerate
	reg env_reset;
	always @(posedge CLK)
		if (RESET) begin
			ymreg <= {16 {8'd0}};
			addr <= 1'sb0;
			env_reset <= 0;
		end
		else if (SNA_LOAD) begin : sv2v_autoblock_1
			integer i;
			for (i = 0; i < 16; i = i + 1)
				ymreg[(15 - i) * 8+:8] <= SNA_REGS[i * 8+:8];
			addr <= {4'h0, SNA_ADDR};
			env_reset <= 1;
		end
		else begin
			env_reset <= 0;
			if (BDIR) begin
				if (BC)
					addr <= DI;
				else if (!addr[7:4]) begin
					ymreg[(15 - addr[3:0]) * 8+:8] <= DI;
					env_reset <= addr == 13;
				end
			end
		end
	reg [7:0] dout;
	assign DO = dout;
	always @(*) begin
		if (_sv2v_0)
			;
		dout = 8'hff;
		if ((~BDIR & BC) & !addr[7:4])
			case (addr[3:0])
				0: dout = ymreg[120+:8];
				1: dout = ymreg[115-:4];
				2: dout = ymreg[104+:8];
				3: dout = ymreg[99-:4];
				4: dout = ymreg[88+:8];
				5: dout = ymreg[83-:4];
				6: dout = ymreg[76-:5];
				7: dout = ymreg[64+:8];
				8: dout = ymreg[60-:5];
				9: dout = ymreg[52-:5];
				10: dout = ymreg[44-:5];
				11: dout = ymreg[32+:8];
				12: dout = ymreg[24+:8];
				13: dout = ymreg[19-:4];
				14: dout = (ymreg[70] ? ymreg[8+:8] & IOA_in : IOA_in);
				15: dout = (ymreg[71] ? ymreg[0+:8] & IOA_in : IOB_in);
			endcase
	end
	reg ena_div;
	reg ena_div_noise;
	always @(posedge CLK) begin : sv2v_autoblock_2
		reg [3:0] cnt_div;
		reg noise_div;
		if (CE) begin
			ena_div <= 0;
			ena_div_noise <= 0;
			if (!cnt_div) begin
				cnt_div <= {SEL, 3'b111};
				ena_div <= 1;
				noise_div <= ~noise_div;
				if (noise_div)
					ena_div_noise <= 1;
			end
			else
				cnt_div <= cnt_div - 1'b1;
		end
	end
	reg [2:0] noise_gen_op;
	always @(posedge CLK) begin : sv2v_autoblock_3
		reg [16:0] poly17;
		reg [4:0] noise_gen_cnt;
		if (CE) begin
			if (ena_div_noise) begin
				if (!ymreg[76-:5] || (noise_gen_cnt >= (ymreg[76-:5] - 1'd1))) begin
					noise_gen_cnt <= 0;
					poly17 <= {(poly17[0] ^ poly17[2]) ^ !poly17, poly17[16:1]};
				end
				else
					noise_gen_cnt <= noise_gen_cnt + 1'd1;
				noise_gen_op <= {3 {poly17[0]}};
			end
		end
	end
	wire [11:0] tone_gen_freq [1:3];
	assign tone_gen_freq[1] = {ymreg[115-:4], ymreg[120+:8]};
	assign tone_gen_freq[2] = {ymreg[99-:4], ymreg[104+:8]};
	assign tone_gen_freq[3] = {ymreg[83-:4], ymreg[88+:8]};
	reg [3:1] tone_gen_op;
	always @(posedge CLK) begin : sv2v_autoblock_4
		integer i;
		reg [11:0] tone_gen_cnt [1:3];
		if (CE) begin
			for (i = 1; i <= 3; i = i + 1)
				if (ena_div) begin
					if (!tone_gen_freq[i] || (tone_gen_cnt[i] >= (tone_gen_freq[i] - 1'd1))) begin
						tone_gen_cnt[i] <= 0;
						tone_gen_op[i] <= ~tone_gen_op[i];
					end
					else
						tone_gen_cnt[i] <= tone_gen_cnt[i] + 1'd1;
				end
		end
	end
	reg env_ena;
	wire [15:0] env_gen_comp = ({ymreg[24+:8], ymreg[32+:8]} ? {ymreg[24+:8], ymreg[32+:8]} - 1'd1 : 16'd0);
	always @(posedge CLK) begin : sv2v_autoblock_5
		reg [15:0] env_gen_cnt;
		if (CE) begin
			env_ena <= 0;
			if (ena_div) begin
				if (env_gen_cnt >= env_gen_comp) begin
					env_gen_cnt <= 0;
					env_ena <= 1;
				end
				else
					env_gen_cnt <= env_gen_cnt + 1'd1;
			end
		end
	end
	reg [4:0] env_vol;
	wire is_bot = env_vol == 5'b00000;
	wire is_bot_p1 = env_vol == 5'b00001;
	wire is_top_m1 = env_vol == 5'b11110;
	wire is_top = env_vol == 5'b11111;
	always @(posedge CLK) begin : sv2v_autoblock_6
		reg env_hold;
		reg env_inc;
		if (env_reset | RESET) begin
			if (!ymreg[18]) begin
				env_vol <= 5'b11111;
				env_inc <= 0;
			end
			else begin
				env_vol <= 5'b00000;
				env_inc <= 1;
			end
			env_hold <= 0;
		end
		else if (CE) begin
			if (env_ena) begin
				if (!env_hold) begin
					if (env_inc)
						env_vol <= env_vol + 5'b00001;
					else
						env_vol <= env_vol + 5'b11111;
				end
				if (!ymreg[19]) begin
					if (!env_inc) begin
						if (is_bot_p1)
							env_hold <= 1;
					end
					else if (is_top)
						env_hold <= 1;
				end
				else if (ymreg[16]) begin
					if (!env_inc) begin
						if (ymreg[17]) begin
							if (is_bot)
								env_hold <= 1;
						end
						else if (is_bot_p1)
							env_hold <= 1;
					end
					else if (ymreg[17]) begin
						if (is_top)
							env_hold <= 1;
					end
					else if (is_top_m1)
						env_hold <= 1;
				end
				else if (ymreg[17]) begin
					if (env_inc == 1'b0) begin
						if (is_bot_p1)
							env_hold <= 1;
						if (is_bot) begin
							env_hold <= 0;
							env_inc <= 1;
						end
					end
					else begin
						if (is_top_m1)
							env_hold <= 1;
						if (is_top) begin
							env_hold <= 0;
							env_inc <= 0;
						end
					end
				end
			end
		end
	end
	reg [5:0] A;
	reg [5:0] B;
	reg [5:0] C;
	always @(posedge CLK) begin
		A <= {MODE, (~((ymreg[64] | tone_gen_op[1]) & (ymreg[67] | noise_gen_op[0])) ? 5'd0 : (ymreg[60] ? env_vol[4:0] : {ymreg[59-:4], ymreg[59]}))};
		B <= {MODE, (~((ymreg[65] | tone_gen_op[2]) & (ymreg[68] | noise_gen_op[1])) ? 5'd0 : (ymreg[52] ? env_vol[4:0] : {ymreg[51-:4], ymreg[51]}))};
		C <= {MODE, (~((ymreg[66] | tone_gen_op[3]) & (ymreg[69] | noise_gen_op[2])) ? 5'd0 : (ymreg[44] ? env_vol[4:0] : {ymreg[43-:4], ymreg[43]}))};
	end
	wire [511:0] volTable = 512'h10102020303040607090a0c0e1113171b20252c353e4754667788a1c0e0ff00000303040406060a0a0f0f15152222282841415b5b72729090b5b5d7d7ffff;
	assign CHANNEL_A = volTable[(63 - A) * 8+:8];
	assign CHANNEL_B = volTable[(63 - B) * 8+:8];
	assign CHANNEL_C = volTable[(63 - C) * 8+:8];
	initial _sv2v_0 = 0;
endmodule
