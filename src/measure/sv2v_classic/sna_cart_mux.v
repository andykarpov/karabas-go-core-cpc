module sna_cart_mux (
	clk,
	clkref,
	a_req,
	a_wr,
	a_bank,
	a_addr,
	a_din,
	a_ack,
	a_grant,
	b_req,
	b_bank,
	b_addr,
	b_ack,
	cart_req,
	cart_wr,
	cart_bank,
	cart_addr,
	cart_din,
	cart_ack,
	cart_grant
);
	input clk;
	input clkref;
	input a_req;
	input a_wr;
	input [1:0] a_bank;
	input [22:0] a_addr;
	input [7:0] a_din;
	output wire a_ack;
	output wire a_grant;
	input b_req;
	input [1:0] b_bank;
	input [22:0] b_addr;
	output wire b_ack;
	output wire cart_req;
	output wire cart_wr;
	output wire [1:0] cart_bank;
	output wire [22:0] cart_addr;
	output wire [7:0] cart_din;
	input cart_ack;
	input cart_grant;
	reg owner_b;
	reg yielding;
	reg [1:0] drain;
	reg clkref_d;
	initial begin
		owner_b = 1'b0;
		yielding = 1'b0;
		drain = 2'd0;
		clkref_d = 1'b0;
	end
	wire owner_req = (owner_b ? b_req : a_req);
	wire other_req = (owner_b ? a_req : b_req);
	always @(posedge clk) begin
		clkref_d <= clkref;
		if (!yielding) begin
			drain <= 2'd0;
			if (!owner_req && other_req)
				yielding <= 1'b1;
		end
		else if (drain == 2'd2) begin
			owner_b <= ~owner_b;
			yielding <= 1'b0;
			drain <= 2'd0;
		end
		else if (clkref && !clkref_d)
			drain <= drain + 2'd1;
	end
	assign cart_req = owner_req && !yielding;
	assign cart_wr = (owner_b ? 1'b0 : a_wr);
	assign cart_bank = (owner_b ? b_bank : a_bank);
	assign cart_addr = (owner_b ? b_addr : a_addr);
	assign cart_din = (owner_b ? 8'd0 : a_din);
	assign a_ack = !owner_b && cart_ack;
	assign a_grant = !owner_b && cart_grant;
	assign b_ack = owner_b && cart_ack;
endmodule
