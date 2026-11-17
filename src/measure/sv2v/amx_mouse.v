module amx_mouse (
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
	output wire [6:0] dout;
	reg [6:0] data;
	assign dout = data;
	reg [11:0] dx;
	reg [11:0] dy;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_sel;
		reg old_stb;
		data[6:4] <= {ps2_mouse[2], ps2_mouse[0], ps2_mouse[1]};
		old_stb <= ps2_mouse[24];
		if (old_stb != ps2_mouse[24]) begin
			dx <= dx + {{4 {ps2_mouse[4]}}, ps2_mouse[15:8]};
			dy <= dy + {{4 {ps2_mouse[5]}}, ps2_mouse[23:16]};
		end
		else begin
			if (!data[1:0] && dx) begin
				if (dx[11]) begin
					data[1:0] <= 2'b10;
					dx <= ($signed(dx) > -12'd4 ? 12'd0 : dx + 12'd4);
				end
				else begin
					data[1:0] <= 2'b01;
					dx <= ($signed(dx) < 12'd4 ? 12'd0 : dx - 12'd4);
				end
			end
			if (!data[3:2] && dy) begin
				if (dy[11]) begin
					data[3:2] <= 2'b01;
					dy <= ($signed(dy) > -12'd4 ? 12'd0 : dy + 12'd4);
				end
				else begin
					data[3:2] <= 2'b10;
					dy <= ($signed(dy) < 12'd4 ? 12'd0 : dy - 12'd4);
				end
			end
		end
		old_sel <= sel;
		if (old_sel & ~sel)
			data <= 0;
		if (reset)
			{data, dx, dy} <= 0;
	end
endmodule
