module plus_sna_apply (
	clk,
	sna_download,
	romdl_wait,
	boot_wr,
	sna_rle_count,
	plus_sna_busy,
	finish_pending,
	apply_cnt,
	sna_load,
	sna_hold,
	owner_reset_hold
);
	input clk;
	input sna_download;
	input romdl_wait;
	input boot_wr;
	input [7:0] sna_rle_count;
	input plus_sna_busy;
	output reg finish_pending;
	output reg [2:0] apply_cnt;
	output wire sna_load;
	output wire sna_hold;
	output wire owner_reset_hold;
	assign sna_load = (apply_cnt == 3'd1) && !sna_download;
	reg old_sna_download;
	assign sna_hold = ((sna_download | old_sna_download) | finish_pending) | (apply_cnt != 3'd0);
	assign owner_reset_hold = ((sna_download | old_sna_download) | finish_pending) | (apply_cnt > 3'd2);
	always @(posedge clk) begin
		old_sna_download <= sna_download;
		if (sna_download && !old_sna_download) begin
			finish_pending <= 1'b0;
			apply_cnt <= 3'd0;
		end
		else if (old_sna_download & ~sna_download)
			finish_pending <= 1'b1;
		else if ((((finish_pending && !romdl_wait) && !boot_wr) && (sna_rle_count == 8'd0)) && !plus_sna_busy) begin
			finish_pending <= 1'b0;
			apply_cnt <= 3'd5;
		end
		else if (apply_cnt != 3'd0)
			apply_cnt <= apply_cnt - 1'd1;
	end
	initial begin
		finish_pending = 1'b0;
		apply_cnt = 3'd0;
		old_sna_download = 1'b0;
	end
endmodule
