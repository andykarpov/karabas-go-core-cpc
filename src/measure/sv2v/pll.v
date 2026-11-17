module pll (
	refclk,
	rst,
	outclk_0,
	locked
);
	input refclk;
	input rst;
	output wire outclk_0;
	output wire locked;
	assign outclk_0 = refclk;
	assign locked = ~rst;
endmodule
