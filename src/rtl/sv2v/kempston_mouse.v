`default_nettype wire
module kempston_mouse (
	clk_sys,
	reset,
	ps2_mouse,
	addr,
	sel,
	dout
);
	input clk_sys;
	input reset;
	input [24:0] ps2_mouse;
	input [2:0] addr;
	output wire sel;
	output wire [7:0] dout;
	reg [7:0] data;
	assign dout = data;
	reg port_sel;
	assign sel = port_sel;
	reg [11:0] dx;
	reg [11:0] dy;
	always @(*) begin
		port_sel = 1;
		casex (addr)
			3'b011: data = dx[7:0];
			3'b111: data = dy[7:0];
			3'bx10: data = ~{5'b00000, ps2_mouse[2], ps2_mouse[0], ps2_mouse[1]};
			default: {port_sel, data} = 8'hff;
		endcase
	end
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_status;
		old_status <= ps2_mouse[24];
		if (reset) begin
			dx <= 128;
			dy <= 0;
		end
		else if (old_status != ps2_mouse[24]) begin
			dx <= dx + {{4 {ps2_mouse[4]}}, ps2_mouse[15:8]};
			dy <= dy + {{4 {ps2_mouse[5]}}, ps2_mouse[23:16]};
		end
	end
endmodule
