module sna_save_stream (
	clk,
	reset,
	start,
	ram128,
	bank,
	header,
	clkref,
	cart_req,
	cart_bank,
	cart_addr,
	cart_dout,
	cart_ack,
	ddr_grant,
	ddr_request,
	ddram_addr,
	ddram_din,
	ddram_be,
	ddram_burstcnt,
	ddram_we,
	ddram_busy,
	done,
	active
);
	input clk;
	input reset;
	input start;
	input ram128;
	input [1:0] bank;
	input [2047:0] header;
	input clkref;
	output reg cart_req;
	output wire [1:0] cart_bank;
	output reg [22:0] cart_addr;
	input [7:0] cart_dout;
	input cart_ack;
	input ddr_grant;
	output reg ddr_request;
	output reg [28:0] ddram_addr;
	output reg [63:0] ddram_din;
	output wire [7:0] ddram_be;
	output wire [7:0] ddram_burstcnt;
	output reg ddram_we;
	input ddram_busy;
	output reg done;
	output wire active;
	localparam [28:0] BASE_WORD = 29'h07c00000;
	assign ddram_be = 8'hff;
	assign ddram_burstcnt = 8'd1;
	localparam [3:0] S_IDLE = 4'd0;
	localparam [3:0] S_WAIT_GRANT = 4'd1;
	localparam [3:0] S_WRITE_INVALID_GEN = 4'd2;
	localparam [3:0] S_WAIT_INVALID_GEN = 4'd3;
	localparam [3:0] S_WRITE_HDR_WORD = 4'd4;
	localparam [3:0] S_WAIT_HDR_WORD = 4'd5;
	localparam [3:0] S_RAM_REQ = 4'd6;
	localparam [3:0] S_RAM_WAIT_ACK = 4'd7;
	localparam [3:0] S_WRITE_RAM_WORD = 4'd8;
	localparam [3:0] S_WAIT_RAM_WORD = 4'd9;
	localparam [3:0] S_WRITE_LEN = 4'd10;
	localparam [3:0] S_WAIT_LEN = 4'd11;
	localparam [3:0] S_WRITE_GEN = 4'd12;
	localparam [3:0] S_WAIT_GEN = 4'd13;
	localparam [3:0] S_QUIESCE = 4'd14;
	reg [3:0] state;
	assign active = state != S_IDLE;
	reg saved_ram128;
	reg [1:0] saved_bank;
	assign cart_bank = saved_bank;
	reg [4:0] hdr_word_idx;
	reg [2:0] ram_page;
	reg [13:0] ram_offset;
	reg [2:0] byte_idx;
	reg [14:0] payload_word_idx;
	reg [63:0] word_buf;
	reg [31:0] generation;
	localparam [1:0] Y_IDLE = 2'd0;
	localparam [1:0] Y_WAIT_REF = 2'd1;
	localparam [1:0] Y_WAIT_ARB = 2'd2;
	reg [1:0] yield_state;
	reg clkref_d;
	wire clkref_rising = clkref && !clkref_d;
	always @(posedge clk) begin
		clkref_d <= clkref;
		if (reset) begin
			cart_req <= 1'b0;
			yield_state <= Y_IDLE;
			done <= 1'b0;
			if (ddram_we && ddram_busy)
				state <= S_QUIESCE;
			else begin
				state <= S_IDLE;
				ddr_request <= 1'b0;
				ddram_we <= 1'b0;
			end
		end
		else if (state == S_QUIESCE) begin
			if (!ddram_busy) begin
				ddram_we <= 1'b0;
				ddr_request <= 1'b0;
				state <= S_IDLE;
			end
		end
		else begin
			done <= 1'b0;
			case (yield_state)
				Y_IDLE:
					;
				Y_WAIT_REF:
					if (clkref_rising)
						yield_state <= Y_WAIT_ARB;
				Y_WAIT_ARB: yield_state <= Y_IDLE;
				default: yield_state <= Y_IDLE;
			endcase
			case (state)
				S_IDLE: begin
					ddram_we <= 1'b0;
					cart_req <= 1'b0;
					if (start) begin
						saved_ram128 <= ram128;
						saved_bank <= bank;
						ddr_request <= 1'b1;
						state <= S_WAIT_GRANT;
					end
				end
				S_WAIT_GRANT:
					if (ddr_grant) begin
						ddram_addr <= BASE_WORD + 29'd0;
						ddram_din <= 64'hffffffffffffffff;
						ddram_we <= 1'b1;
						state <= S_WAIT_INVALID_GEN;
					end
				S_WAIT_INVALID_GEN:
					if (!ddram_busy) begin
						ddram_we <= 1'b0;
						hdr_word_idx <= 5'd0;
						state <= S_WRITE_HDR_WORD;
					end
				S_WRITE_HDR_WORD: begin
					ddram_addr <= (BASE_WORD + 29'd2) + {24'd0, hdr_word_idx};
					ddram_din <= header[hdr_word_idx * 64+:64];
					ddram_we <= 1'b1;
					state <= S_WAIT_HDR_WORD;
				end
				S_WAIT_HDR_WORD:
					if (!ddram_busy) begin
						ddram_we <= 1'b0;
						if (hdr_word_idx == 5'd31) begin
							ram_page <= 3'd0;
							ram_offset <= 14'd0;
							byte_idx <= 3'd0;
							payload_word_idx <= 15'd32;
							state <= S_RAM_REQ;
						end
						else begin
							hdr_word_idx <= hdr_word_idx + 5'd1;
							state <= S_WRITE_HDR_WORD;
						end
					end
				S_RAM_REQ:
					if (yield_state == Y_IDLE) begin
						cart_addr <= {9'd8 + {6'd0, ram_page}, ram_offset[13:3], byte_idx};
						cart_req <= 1'b1;
						state <= S_RAM_WAIT_ACK;
					end
				S_RAM_WAIT_ACK:
					if (cart_ack) begin
						word_buf[byte_idx * 8+:8] <= cart_dout;
						cart_req <= 1'b0;
						yield_state <= Y_WAIT_REF;
						if (byte_idx == 3'd7)
							state <= S_WRITE_RAM_WORD;
						else begin
							byte_idx <= byte_idx + 3'd1;
							state <= S_RAM_REQ;
						end
					end
				S_WRITE_RAM_WORD: begin
					ddram_addr <= (BASE_WORD + 29'd2) + {14'd0, payload_word_idx};
					ddram_din <= word_buf;
					ddram_we <= 1'b1;
					state <= S_WAIT_RAM_WORD;
				end
				S_WAIT_RAM_WORD:
					if (!ddram_busy) begin
						ddram_we <= 1'b0;
						payload_word_idx <= payload_word_idx + 15'd1;
						byte_idx <= 3'd0;
						if (ram_offset == 14'h3ff8) begin
							ram_offset <= 14'd0;
							if (ram_page == (saved_ram128 ? 3'd7 : 3'd3))
								state <= S_WRITE_LEN;
							else begin
								ram_page <= ram_page + 3'd1;
								state <= S_RAM_REQ;
							end
						end
						else begin
							ram_offset <= ram_offset + 14'd8;
							state <= S_RAM_REQ;
						end
					end
				S_WRITE_LEN: begin
					ddram_addr <= BASE_WORD + 29'd1;
					ddram_din <= (saved_ram128 ? 64'h0000000000008040 : 64'h0000000000004040);
					ddram_we <= 1'b1;
					state <= S_WAIT_LEN;
				end
				S_WAIT_LEN:
					if (!ddram_busy) begin
						ddram_we <= 1'b0;
						state <= S_WRITE_GEN;
					end
				S_WRITE_GEN: begin
					ddram_addr <= BASE_WORD + 29'd0;
					ddram_din <= {32'd0, generation};
					ddram_we <= 1'b1;
					generation <= (generation == 32'hfffffffe ? 32'd1 : generation + 32'd1);
					state <= S_WAIT_GEN;
				end
				S_WAIT_GEN:
					if (!ddram_busy) begin
						ddram_we <= 1'b0;
						ddr_request <= 1'b0;
						done <= 1'b1;
						state <= S_IDLE;
					end
				default: state <= S_IDLE;
			endcase
		end
	end
	initial begin
		state = S_IDLE;
		cart_req = 1'b0;
		cart_addr = 23'd0;
		ddr_request = 1'b0;
		ddram_addr = 29'd0;
		ddram_din = 64'd0;
		ddram_we = 1'b0;
		done = 1'b0;
		generation = 32'd1;
		saved_ram128 = 1'b0;
		saved_bank = 2'd0;
		hdr_word_idx = 5'd0;
		ram_page = 3'd0;
		ram_offset = 14'd0;
		byte_idx = 3'd0;
		payload_word_idx = 15'd0;
		word_buf = 64'd0;
		yield_state = Y_IDLE;
		clkref_d = 1'b0;
	end
endmodule
