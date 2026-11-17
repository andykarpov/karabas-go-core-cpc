module rslatch (
	clock,
	s,
	r,
	q
);
	input clock;
	input s;
	input r;
	parameter WIDTH = 1;
	output reg [WIDTH - 1:0] q;
	parameter PRIO_SET = 1;
	reg [WIDTH - 1:0] val_reg;
	always @(*)
		if (PRIO_SET) begin
			if (s)
				q = 1;
			else if (r)
				q = 0;
			else
				q = val_reg;
		end
		else if (r)
			q = 0;
		else if (s)
			q = 1;
		else
			q = val_reg;
	always @(posedge clock) val_reg <= q;
endmodule
