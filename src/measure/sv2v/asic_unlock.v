module asic_unlock (
	clk,
	RESET_N,
	write_strobe,
	write_data,
	unlocked,
	sna_load,
	sna_unlock,
	sna_seq_state
);
	input clk;
	input RESET_N;
	input write_strobe;
	input [7:0] write_data;
	output reg unlocked;
	input sna_load;
	input sna_unlock;
	input [4:0] sna_seq_state;
	reg matching_sequence;
	reg previous_nonzero;
	reg [3:0] sequence_index;
	function [7:0] sequence_byte;
		input [3:0] index;
		case (index)
			4'd0: sequence_byte = 8'hff;
			4'd1: sequence_byte = 8'h77;
			4'd2: sequence_byte = 8'hb3;
			4'd3: sequence_byte = 8'h51;
			4'd4: sequence_byte = 8'ha8;
			4'd5: sequence_byte = 8'hd4;
			4'd6: sequence_byte = 8'h62;
			4'd7: sequence_byte = 8'h39;
			4'd8: sequence_byte = 8'h9c;
			4'd9: sequence_byte = 8'h46;
			4'd10: sequence_byte = 8'h2b;
			4'd11: sequence_byte = 8'h15;
			4'd12: sequence_byte = 8'h8a;
			default: sequence_byte = 8'h00;
		endcase
	endfunction
	always @(posedge clk or negedge RESET_N)
		if (!RESET_N) begin
			unlocked <= 1'b0;
			matching_sequence <= 1'b0;
			previous_nonzero <= 1'b0;
			sequence_index <= 4'd0;
		end
		else if (sna_load) begin
			unlocked <= sna_unlock;
			case (sna_seq_state)
				5'd0: begin
					matching_sequence <= 1'b0;
					previous_nonzero <= 1'b0;
					sequence_index <= 4'd0;
				end
				5'd1: begin
					matching_sequence <= 1'b0;
					previous_nonzero <= 1'b1;
					sequence_index <= 4'd0;
				end
				5'd15: begin
					matching_sequence <= 1'b1;
					previous_nonzero <= 1'b1;
					sequence_index <= 4'd13;
				end
				5'd16: begin
					matching_sequence <= 1'b0;
					previous_nonzero <= 1'b1;
					sequence_index <= 4'd0;
				end
				default:
					if ((sna_seq_state >= 5'd2) && (sna_seq_state <= 5'd14)) begin
						matching_sequence <= 1'b1;
						previous_nonzero <= (sna_seq_state == 5'd2 ? 1'b0 : 1'b1);
						sequence_index <= sna_seq_state[3:0] - 4'd2;
					end
					else begin
						matching_sequence <= 1'b0;
						previous_nonzero <= 1'b0;
						sequence_index <= 4'd0;
					end
			endcase
		end
		else if (write_strobe) begin
			previous_nonzero <= write_data != 8'h00;
			if (!matching_sequence) begin
				if (previous_nonzero && (write_data == 8'h00)) begin
					matching_sequence <= 1'b1;
					sequence_index <= 4'd0;
				end
			end
			else if (sequence_index < 4'd13) begin
				if (write_data == sequence_byte(sequence_index))
					sequence_index <= sequence_index + 4'd1;
				else if ((sequence_index == 4'd0) && (write_data == 8'h00)) begin
					matching_sequence <= 1'b1;
					sequence_index <= 4'd0;
				end
				else begin
					matching_sequence <= previous_nonzero && (write_data == 8'h00);
					sequence_index <= 4'd0;
				end
			end
			else begin
				unlocked <= write_data == 8'hcd;
				matching_sequence <= previous_nonzero && (write_data == 8'h00);
				sequence_index <= 4'd0;
			end
		end
endmodule
