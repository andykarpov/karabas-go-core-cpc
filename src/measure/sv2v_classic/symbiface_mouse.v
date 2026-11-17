module symbiface_mouse (
	clk_sys,
	reset,
	ps2_mouse,
	sel,
	dout
);
	input clk_sys;
	input reset;
	input [24:0] ps2_mouse;
	input sel;
	output wire [7:0] dout;
	reg [7:0] data;
	assign dout = data;
	wire signed [8:0] dxp = {ps2_mouse[4], ps2_mouse[15:8]};
	wire signed [5:0] dx = (dxp > 31 ? 6'd31 : (dxp < -32 ? -6'd32 : dxp[5:0]));
	wire signed [8:0] dyp = {ps2_mouse[5], ps2_mouse[23:16]};
	wire signed [5:0] dy = (dyp > 31 ? 6'd31 : (dyp < -32 ? -6'd32 : dyp[5:0]));
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg [2:0] avail;
		reg old_status;
		reg old_sel;
		old_status <= ps2_mouse[24];
		if (old_status != ps2_mouse[24])
			avail <= {|dy, |dx, 1'b1};
		old_sel <= sel;
		if (~old_sel & sel)
			casex (avail)
				'b1xx: {avail[2], data} <= {3'b010, dy};
				'b1x: {avail[1], data} <= {3'b001, dx};
				'b1: {avail[0], data} <= {6'b011000, ps2_mouse[2:0]};
				'b0: data <= 0;
			endcase
		if (~sel)
			data <= 8'hff;
		if (reset)
			avail <= 0;
	end
endmodule
