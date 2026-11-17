`default_nettype wire
module mouse_axis (
	clk,
	set,
	offset,
	reset,
	dir
);
	input clk;
	input set;
	input [8:0] offset;
	input reset;
	output reg [1:0] dir;
	localparam [8:0] step = 2;
	reg signed [8:0] counter;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg old_reset;
		if (set)
			counter <= offset;
		else begin
			old_reset <= reset;
			if (~old_reset & reset)
				dir <= 0;
			else if (!dir && counter) begin
				if (counter > 0) begin
					dir[0] <= 1;
					if (counter > step)
						counter <= counter - step;
					else
						counter <= 0;
				end
				else begin
					dir[1] <= 1;
					if ((counter + step) < 0)
						counter <= counter + step;
					else
						counter <= 0;
				end
			end
		end
	end
endmodule
