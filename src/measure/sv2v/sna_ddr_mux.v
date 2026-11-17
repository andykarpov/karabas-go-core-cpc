module sna_ddr_mux (
	clk,
	reset,
	a_addr,
	a_din,
	a_be,
	a_burstcnt,
	a_we,
	a_busy,
	b_request,
	b_grant,
	b_addr,
	b_din,
	b_be,
	b_burstcnt,
	b_we,
	b_busy,
	ddram_addr,
	ddram_din,
	ddram_be,
	ddram_burstcnt,
	ddram_we,
	ddram_busy
);
	input clk;
	input reset;
	input [28:0] a_addr;
	input [63:0] a_din;
	input [7:0] a_be;
	input [7:0] a_burstcnt;
	input a_we;
	output wire a_busy;
	input b_request;
	output reg b_grant;
	input [28:0] b_addr;
	input [63:0] b_din;
	input [7:0] b_be;
	input [7:0] b_burstcnt;
	input b_we;
	output wire b_busy;
	output wire [28:0] ddram_addr;
	output wire [63:0] ddram_din;
	output wire [7:0] ddram_be;
	output wire [7:0] ddram_burstcnt;
	output wire ddram_we;
	input ddram_busy;
	always @(posedge clk)
		if (!b_grant) begin
			if ((!reset && b_request) && !a_we)
				b_grant <= 1'b1;
		end
		else if ((reset || !b_request) && !b_we)
			b_grant <= 1'b0;
	initial b_grant = 1'b0;
	assign a_busy = (b_grant ? 1'b1 : ddram_busy);
	assign b_busy = (b_grant ? ddram_busy : 1'b1);
	assign ddram_addr = (b_grant ? b_addr : a_addr);
	assign ddram_din = (b_grant ? b_din : a_din);
	assign ddram_be = (b_grant ? b_be : a_be);
	assign ddram_burstcnt = (b_grant ? b_burstcnt : a_burstcnt);
	assign ddram_we = (b_grant ? b_we : a_we);
endmodule
