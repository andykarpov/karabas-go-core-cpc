`default_nettype wire
module cpc_sram (
	init,
	clk,
	clkref,
	bank,
	din,
	dout,
	addr,
	oe,
	we,
	cart_req,
	cart_wr,
	cart_bank,
	cart_addr,
	cart_din,
	cart_dout,
	cart_ack,
	cart_grant,
	vram_dout,
	vram_addr,
	vram_bank,
	tape_addr,
	tape_din,
	tape_dout,
	tape_wr,
	tape_wr_ack,
	tape_rd,
	tape_rd_ack,
	MA,
	MD_I,
	MD_O,
	MD_OE,
	MWR_N,
	MRD_N
);
	input init;
	input clk;
	input clkref;
	input [1:0] bank;
	input [7:0] din;
	output wire [7:0] dout;
	input [22:0] addr;
	input oe;
	input we;
	input cart_req;
	input cart_wr;
	input [1:0] cart_bank;
	input [22:0] cart_addr;
	input [7:0] cart_din;
	output reg [7:0] cart_dout;
	output reg cart_ack;
	output reg cart_grant;
	output reg [15:0] vram_dout;
	input [22:0] vram_addr;
	input [1:0] vram_bank;
	input [22:0] tape_addr;
	input [7:0] tape_din;
	output reg [7:0] tape_dout;
	input tape_wr;
	output reg tape_wr_ack;
	input tape_rd;
	output reg tape_rd_ack;
	output reg [20:0] MA = 21'd0;
	input [15:0] MD_I;
	output reg [15:0] MD_O = 16'd0;
	output reg MD_OE = 1'b0;
	output reg [1:0] MWR_N = 2'b11;
	output reg [1:0] MRD_N = 2'b11;
	localparam STATE_IDLE = 3'd0;
	localparam STATE_START = 3'd1;
	localparam STATE_TAKE = 3'd5;
	localparam STATE_READ = 3'd6;
	localparam STATE_READY = 3'd7;
	localparam [1:0] TAPE_BANK = 2'b11;
	localparam [22:0] TAPE_BASE = 23'h100000;
	initial begin
		cart_dout = 8'd0;
		cart_ack = 1'b0;
		cart_grant = 1'b0;
		vram_dout = 16'd0;
		tape_dout = 8'd0;
		tape_wr_ack = 1'b0;
		tape_rd_ack = 1'b0;
	end
	function [7:0] phys_page;
		input [1:0] b;
		input [8:0] p;
		if ((p >= 9'h008) && (p <= 9'h02b))
			phys_page = {2'b00, p[5:0]};
		else if ((b != 2'b11) && (p == 9'h000))
			phys_page = {6'd0, b};
		else if ((b != 2'b11) && (p == 9'h0ff))
			phys_page = {6'd1, b};
		else if ((b != 2'b11) && (p[8:5] == 4'b1000))
			phys_page = 8'h40 + {b, p[4:0]};
		else if ((b == 2'b11) && (p[8:5] == 4'b0000))
			phys_page = {3'b101, p[4:0]};
		else if ((b == 2'b11) && (p[8:6] == 3'b001))
			phys_page = {2'b11, p[5:0]};
		else
			phys_page = 8'h3f;
	endfunction
	reg [2:0] q = 3'd0;
	reg [22:0] a = 23'd0;
	reg [1:0] active_bank = 2'b00;
	reg wr = 1'b0;
	reg ram_req = 1'b0;
	reg vram_req = 1'b0;
	reg tape_req = 1'b0;
	reg cart_active = 1'b0;
	reg [22:1] vram_cached_addr = 22'd0;
	reg [1:0] vram_cached_bank = 2'b00;
	reg vram_cached_valid = 1'b0;
	reg [7:0] wdata = 8'd0;
	reg [7:0] ram_dout = 8'hff;
	reg [15:0] rword = 16'hffff;
	reg old_rd = 1'b0;
	reg old_we = 1'b0;
	reg old_ref = 1'b0;
	assign dout = (oe | we ? ram_dout : 8'hff);
	wire [22:0] tape_phys_addr = tape_addr + TAPE_BASE;
	always @(posedge clk) begin
		old_rd <= oe;
		old_we <= we;
		old_ref <= clkref;
		cart_grant <= 1'b0;
		if (init)
			vram_cached_valid <= 1'b0;
		if (q == STATE_IDLE) begin
			ram_req <= 1'b0;
			vram_req <= 1'b0;
			tape_req <= 1'b0;
			cart_active <= 1'b0;
			wr <= 1'b0;
			if (!init && ((~old_rd & oe) | (~old_we & we))) begin
				ram_req <= 1'b1;
				wr <= we;
				a <= addr;
				active_bank <= bank;
				wdata <= din;
				if (((we && vram_cached_valid) && (bank == vram_cached_bank)) && (addr[22:1] == vram_cached_addr))
					vram_cached_valid <= 1'b0;
			end
			else if (!init && cart_req) begin
				cart_active <= 1'b1;
				cart_grant <= 1'b1;
				wr <= cart_wr;
				a <= cart_addr;
				active_bank <= cart_bank;
				wdata <= cart_din;
				if (((cart_wr && vram_cached_valid) && (cart_bank == vram_cached_bank)) && (cart_addr[22:1] == vram_cached_addr))
					vram_cached_valid <= 1'b0;
			end
			else if (!init && (tape_rd | tape_wr)) begin
				tape_req <= 1'b1;
				wr <= tape_wr;
				a <= tape_phys_addr;
				wdata <= tape_din;
				active_bank <= TAPE_BANK;
				if (((tape_wr && vram_cached_valid) && (TAPE_BANK == vram_cached_bank)) && (tape_phys_addr[22:1] == vram_cached_addr))
					vram_cached_valid <= 1'b0;
			end
			else if (!init && ((!vram_cached_valid || (vram_cached_bank != vram_bank)) || (vram_cached_addr != vram_addr[22:1]))) begin
				vram_req <= 1'b1;
				vram_cached_valid <= 1'b1;
				vram_cached_bank <= vram_bank;
				vram_cached_addr <= vram_addr[22:1];
				active_bank <= vram_bank;
				a <= vram_addr;
			end
		end
		q <= q + 3'd1;
		if (~old_ref & clkref)
			q <= 3'd0;
	end
	wire any_req = ((ram_req | vram_req) | tape_req) | cart_active;
	wire [7:0] page = phys_page(active_bank, a[22:14]);
	always @(posedge clk) begin
		if (q == STATE_START) begin
			MA <= {page, a[13:1]};
			MRD_N <= (any_req && wr ? 2'b11 : 2'b00);
			if (any_req && wr) begin
				MD_O <= {wdata, wdata};
				MD_OE <= 1'b1;
			end
			if (ram_req & wr)
				ram_dout <= din;
		end
		if (((q == 3'd2) && any_req) && wr)
			MWR_N <= (a[0] ? 2'b01 : 2'b10);
		if (q == STATE_TAKE) begin
			MWR_N <= 2'b11;
			rword <= MD_I;
		end
		if (q == STATE_READ) begin
			MD_OE <= 1'b0;
			MRD_N <= 2'b00;
		end
		tape_wr_ack <= 1'b0;
		cart_ack <= 1'b0;
		if ((q == STATE_READ) && cart_active) begin
			if (!wr)
				cart_dout <= (a[0] ? rword[15:8] : rword[7:0]);
			cart_ack <= 1'b1;
		end
		if (((q == STATE_READ) && tape_req) && wr)
			tape_wr_ack <= 1'b1;
		if (q == STATE_READY) begin
			if (~wr & ram_req)
				ram_dout <= (a[0] ? rword[15:8] : rword[7:0]);
			else if (vram_req)
				vram_dout <= rword;
			else if (~wr & tape_req)
				tape_dout <= (a[0] ? rword[15:8] : rword[7:0]);
			if (tape_req && !wr)
				tape_rd_ack <= ~tape_rd_ack;
		end
	end
endmodule
