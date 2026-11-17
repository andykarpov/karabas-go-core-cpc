module video_interlace (
	clk,
	vsync_in,
	field_in,
	scale,
	forced_scandoubler,
	interlace,
	scandoubler
);
	input clk;
	input vsync_in;
	input field_in;
	input [1:0] scale;
	input forced_scandoubler;
	output wire [2:0] interlace;
	output wire scandoubler;
	reg [2:0] interlace_r;
	reg old_vs;
	initial begin
		interlace_r = 3'd0;
		old_vs = 1'b0;
	end
	always @(posedge clk) begin
		old_vs <= vsync_in;
		if (~old_vs & vsync_in)
			interlace_r <= {interlace_r[1:0], field_in};
	end
	assign interlace = interlace_r;
	assign scandoubler = ((scale != 2'd0) || forced_scandoubler) && (interlace_r == 3'd0);
endmodule
