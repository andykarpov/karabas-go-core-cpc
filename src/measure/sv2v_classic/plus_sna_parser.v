module plus_sna_parser (
	clk,
	reset,
	sna_download,
	cpc_plus_chunk_start,
	cpc_plus_byte_wr,
	cpc_plus_byte_data,
	ioctl_wait,
	busy,
	asic_sna_wr,
	asic_sna_addr,
	asic_sna_data,
	asic_sna_active,
	asic_sna_rmr2,
	asic_sna_unlock,
	asic_sna_loop_cnt0,
	asic_sna_loop_cnt1,
	asic_sna_loop_cnt2,
	asic_sna_loop_addr0,
	asic_sna_loop_addr1,
	asic_sna_loop_addr2,
	asic_sna_pause_cnt0,
	asic_sna_pause_cnt1,
	asic_sna_pause_cnt2,
	asic_sna_pause_presc0,
	asic_sna_pause_presc1,
	asic_sna_pause_presc2,
	asic_sna_seq_state
);
	input clk;
	input reset;
	input sna_download;
	input cpc_plus_chunk_start;
	input cpc_plus_byte_wr;
	input [7:0] cpc_plus_byte_data;
	output wire ioctl_wait;
	output wire busy;
	output reg asic_sna_wr;
	output reg [13:0] asic_sna_addr;
	output reg [7:0] asic_sna_data;
	output reg asic_sna_active;
	output reg [7:0] asic_sna_rmr2;
	output reg asic_sna_unlock;
	output wire [11:0] asic_sna_loop_cnt0;
	output wire [11:0] asic_sna_loop_cnt1;
	output wire [11:0] asic_sna_loop_cnt2;
	output wire [15:0] asic_sna_loop_addr0;
	output wire [15:0] asic_sna_loop_addr1;
	output wire [15:0] asic_sna_loop_addr2;
	output wire [11:0] asic_sna_pause_cnt0;
	output wire [11:0] asic_sna_pause_cnt1;
	output wire [11:0] asic_sna_pause_cnt2;
	output wire [7:0] asic_sna_pause_presc0;
	output wire [7:0] asic_sna_pause_presc1;
	output wire [7:0] asic_sna_pause_presc2;
	output wire [4:0] asic_sna_seq_state;
	reg [11:0] sna_loop_cnt [0:2];
	reg [15:0] sna_loop_addr [0:2];
	reg [11:0] sna_pause_cnt [0:2];
	reg [7:0] sna_pause_presc [0:2];
	reg [4:0] sna_seq_state_r;
	reg [7:0] pair_lo;
	reg [15:0] chunk_byte_cnt;
	reg sna_download_d;
	reg [21:0] fifo_mem [0:7];
	reg [3:0] fifo_wr_ptr;
	reg [3:0] fifo_rd_ptr;
	wire [2:0] fifo_wr_idx0 = fifo_wr_ptr[2:0];
	wire [2:0] fifo_wr_idx1 = fifo_wr_ptr[2:0] + 3'd1;
	wire [2:0] fifo_rd_idx = fifo_rd_ptr[2:0];
	wire [3:0] fifo_count = fifo_wr_ptr - fifo_rd_ptr;
	wire fifo_empty = fifo_wr_ptr == fifo_rd_ptr;
	assign asic_sna_loop_cnt0 = sna_loop_cnt[0];
	assign asic_sna_loop_cnt1 = sna_loop_cnt[1];
	assign asic_sna_loop_cnt2 = sna_loop_cnt[2];
	assign asic_sna_loop_addr0 = sna_loop_addr[0];
	assign asic_sna_loop_addr1 = sna_loop_addr[1];
	assign asic_sna_loop_addr2 = sna_loop_addr[2];
	assign asic_sna_pause_cnt0 = sna_pause_cnt[0];
	assign asic_sna_pause_cnt1 = sna_pause_cnt[1];
	assign asic_sna_pause_cnt2 = sna_pause_cnt[2];
	assign asic_sna_pause_presc0 = sna_pause_presc[0];
	assign asic_sna_pause_presc1 = sna_pause_presc[1];
	assign asic_sna_pause_presc2 = sna_pause_presc[2];
	assign asic_sna_seq_state = sna_seq_state_r;
	wire [1:0] sna_int_ch = (chunk_byte_cnt >= 16'h08ee ? 2'd2 : (chunk_byte_cnt >= 16'h08e7 ? 2'd1 : 2'd0));
	wire [2:0] sna_int_base_l3 = (sna_int_ch == 2'd2 ? 3'd6 : (sna_int_ch == 2'd1 ? 3'd7 : 3'd0));
	wire [2:0] sna_int_sub = chunk_byte_cnt[2:0] - sna_int_base_l3;
	assign ioctl_wait = fifo_count >= 4'd3;
	assign busy = ((sna_download || cpc_plus_byte_wr) || !fifo_empty) || asic_sna_wr;
	always @(posedge clk)
		if (reset) begin
			chunk_byte_cnt <= 16'd0;
			sna_download_d <= 1'b0;
			asic_sna_wr <= 1'b0;
			asic_sna_addr <= 14'd0;
			asic_sna_data <= 8'd0;
			asic_sna_active <= 1'b0;
			asic_sna_rmr2 <= 8'd0;
			asic_sna_unlock <= 1'b0;
			sna_loop_cnt[0] <= 12'd0;
			sna_loop_cnt[1] <= 12'd0;
			sna_loop_cnt[2] <= 12'd0;
			sna_loop_addr[0] <= 16'd0;
			sna_loop_addr[1] <= 16'd0;
			sna_loop_addr[2] <= 16'd0;
			sna_pause_cnt[0] <= 12'd0;
			sna_pause_cnt[1] <= 12'd0;
			sna_pause_cnt[2] <= 12'd0;
			sna_pause_presc[0] <= 8'd0;
			sna_pause_presc[1] <= 8'd0;
			sna_pause_presc[2] <= 8'd0;
			sna_seq_state_r <= 5'd0;
			pair_lo <= 8'd0;
			fifo_wr_ptr <= 4'd0;
			fifo_rd_ptr <= 4'd0;
		end
		else begin
			sna_download_d <= sna_download;
			if (sna_download && !sna_download_d) begin
				chunk_byte_cnt <= 16'd0;
				asic_sna_wr <= 1'b0;
				asic_sna_active <= 1'b0;
				asic_sna_rmr2 <= 8'd0;
				asic_sna_unlock <= 1'b0;
				sna_loop_cnt[0] <= 12'd0;
				sna_loop_cnt[1] <= 12'd0;
				sna_loop_cnt[2] <= 12'd0;
				sna_loop_addr[0] <= 16'd0;
				sna_loop_addr[1] <= 16'd0;
				sna_loop_addr[2] <= 16'd0;
				sna_pause_cnt[0] <= 12'd0;
				sna_pause_cnt[1] <= 12'd0;
				sna_pause_cnt[2] <= 12'd0;
				sna_pause_presc[0] <= 8'd0;
				sna_pause_presc[1] <= 8'd0;
				sna_pause_presc[2] <= 8'd0;
				sna_seq_state_r <= 5'd0;
				pair_lo <= 8'd0;
				fifo_wr_ptr <= 4'd0;
				fifo_rd_ptr <= 4'd0;
			end
			if (cpc_plus_chunk_start) begin
				chunk_byte_cnt <= 16'd0;
				asic_sna_active <= 1'b1;
				fifo_wr_ptr <= 4'd0;
				fifo_rd_ptr <= 4'd0;
			end
			if (cpc_plus_byte_wr) begin
				chunk_byte_cnt <= chunk_byte_cnt + 16'd1;
				if (chunk_byte_cnt < 16'h0800) begin
					fifo_mem[fifo_wr_idx0] <= {2'b00, chunk_byte_cnt[10:0], 5'b00000, cpc_plus_byte_data[7:4]};
					fifo_mem[fifo_wr_idx1] <= {2'b00, chunk_byte_cnt[10:0], 5'b10000, cpc_plus_byte_data[3:0]};
					fifo_wr_ptr <= fifo_wr_ptr + 4'd2;
				end
				else if ((chunk_byte_cnt >= 16'h0800) && (chunk_byte_cnt < 16'h0880)) begin
					fifo_mem[fifo_wr_idx0] <= {14'h2000 | {7'd0, chunk_byte_cnt[6:0]}, cpc_plus_byte_data};
					fifo_wr_ptr <= fifo_wr_ptr + 4'd1;
				end
				else if ((chunk_byte_cnt >= 16'h0880) && (chunk_byte_cnt < 16'h08c0)) begin
					fifo_mem[fifo_wr_idx0] <= {14'h2400 | {8'd0, chunk_byte_cnt[5:0]}, cpc_plus_byte_data};
					fifo_wr_ptr <= fifo_wr_ptr + 4'd1;
				end
				else if ((chunk_byte_cnt >= 16'h08c0) && (chunk_byte_cnt <= 16'h08c5)) begin
					fifo_mem[fifo_wr_idx0] <= {14'h2800 + {10'd0, chunk_byte_cnt[3:0] - 4'h0}, cpc_plus_byte_data};
					fifo_wr_ptr <= fifo_wr_ptr + 4'd1;
				end
				else if ((chunk_byte_cnt >= 16'h08d0) && (chunk_byte_cnt <= 16'h08db)) begin
					fifo_mem[fifo_wr_idx0] <= {14'h2c00 + {10'd0, chunk_byte_cnt[3:0] - 4'h0}, cpc_plus_byte_data};
					fifo_wr_ptr <= fifo_wr_ptr + 4'd1;
				end
				else if (chunk_byte_cnt == 16'h08df) begin
					fifo_mem[fifo_wr_idx0] <= {14'h2c0f, cpc_plus_byte_data};
					fifo_wr_ptr <= fifo_wr_ptr + 4'd1;
				end
				else if (chunk_byte_cnt == 16'h08f5)
					asic_sna_rmr2 <= cpc_plus_byte_data;
				else if (chunk_byte_cnt == 16'h08f6)
					asic_sna_unlock <= cpc_plus_byte_data[0];
				else if (chunk_byte_cnt == 16'h08f7)
					sna_seq_state_r <= cpc_plus_byte_data[4:0];
				else if ((chunk_byte_cnt >= 16'h08e0) && (chunk_byte_cnt <= 16'h08f4))
					case (sna_int_sub)
						3'd0: pair_lo <= cpc_plus_byte_data;
						3'd1: sna_loop_cnt[sna_int_ch] <= {cpc_plus_byte_data[3:0], pair_lo};
						3'd2: pair_lo <= cpc_plus_byte_data;
						3'd3: sna_loop_addr[sna_int_ch] <= {cpc_plus_byte_data, pair_lo};
						3'd4: pair_lo <= cpc_plus_byte_data;
						3'd5: sna_pause_cnt[sna_int_ch] <= {cpc_plus_byte_data[3:0], pair_lo};
						3'd6: sna_pause_presc[sna_int_ch] <= cpc_plus_byte_data;
						default:
							;
					endcase
			end
			if (sna_download && !sna_download_d)
				asic_sna_wr <= 1'b0;
			else if (!fifo_empty) begin
				asic_sna_wr <= 1'b1;
				asic_sna_addr <= fifo_mem[fifo_rd_idx][21:8];
				asic_sna_data <= fifo_mem[fifo_rd_idx][7:0];
				fifo_rd_ptr <= fifo_rd_ptr + 4'd1;
			end
			else
				asic_sna_wr <= 1'b0;
		end
endmodule
