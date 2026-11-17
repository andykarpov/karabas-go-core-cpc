`default_nettype wire
module plus_model_select (
	plus_model,
	plus_mode,
	ram_128k,
	has_fdc,
	has_tape
);
	input [1:0] plus_model;
	output reg plus_mode;
	output reg ram_128k;
	output reg has_fdc;
	output reg has_tape;
	always @(*) begin
		plus_mode = 1'b0;
		ram_128k = 1'b0;
		has_fdc = 1'b0;
		has_tape = 1'b0;
		case (plus_model)
			2'b01: plus_mode = 1'b1;
			2'b10: begin
				plus_mode = 1'b1;
				ram_128k = 1'b1;
				has_fdc = 1'b1;
			end
			2'b11: begin
				plus_mode = 1'b1;
				has_tape = 1'b1;
			end
			default:
				;
		endcase
	end
endmodule
