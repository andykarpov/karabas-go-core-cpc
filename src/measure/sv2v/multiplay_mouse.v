module multiplay_mouse (
	clk_sys,
	reset,
	ps2_mouse,
	sel,
	addr,
	dout
);
	input clk_sys;
	input reset;
	input [24:0] ps2_mouse;
	input sel;
	input [2:0] addr;
	output wire [7:0] dout;
	reg [7:0] data;
	assign dout = data;
	wire signed [8:0] dxp = {ps2_mouse[4], ps2_mouse[15:8]};
	wire signed [7:0] dx = (dxp > 7 ? 8'd7 : (dxp < -8 ? -8'd8 : dxp[7:0]));
	wire signed [8:0] dyp = -{ps2_mouse[5], ps2_mouse[23:16]};
	wire signed [7:0] dy = (dyp > 7 ? 8'd7 : (dyp < -8 ? -8'd8 : dyp[7:0]));
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg [1:0] avail;
		reg old_status;
		reg old_sel;
		old_status <= ps2_mouse[24];
		if (old_status != ps2_mouse[24])
			avail <= 3;
		old_sel <= sel;
		if (~old_sel & sel)
			case (addr)
				0: data <= {1'b0, ps2_mouse[2:0], 4'b0000};
				2:
					if (avail[0])
						{avail[0], data} <= {1'b0, dx};
					else
						data <= 0;
				3:
					if (avail[1])
						{avail[1], data} <= {1'b0, dy};
					else
						data <= 0;
				default: data <= 8'hff;
			endcase
		if (~sel)
			data <= 8'hff;
		if (reset)
			avail <= 0;
	end
endmodule
