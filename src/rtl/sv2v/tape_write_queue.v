`default_nettype wire
module tape_write_queue (
	clk,
	reset,
	clear,
	tape_download,
	ioctl_wr,
	ioctl_dout,
	ioctl_addr,
	tape_wr_ack,
	tape_play_addr,
	tape_wr,
	tape_din,
	tape_queued_addr,
	tape_addr,
	tape_wait,
	tape_pending
);
	input clk;
	input reset;
	input clear;
	input tape_download;
	input ioctl_wr;
	input [7:0] ioctl_dout;
	input [22:0] ioctl_addr;
	input tape_wr_ack;
	input [22:0] tape_play_addr;
	output reg tape_wr;
	output reg [7:0] tape_din;
	output reg [22:0] tape_queued_addr;
	output wire [22:0] tape_addr;
	output wire tape_wait;
	output wire tape_pending;
	reg [22:0] pending_addr;
	assign tape_addr = (tape_wr ? pending_addr : (tape_download ? tape_queued_addr : tape_play_addr));
	assign tape_wait = (tape_download & tape_wr) & ~tape_wr_ack;
	assign tape_pending = tape_wr;
	initial begin
		tape_wr = 1'b0;
		tape_din = 8'h00;
		tape_queued_addr = 23'd0;
		pending_addr = 23'd0;
	end
	always @(posedge clk)
		if (reset) begin
			tape_wr <= 1'b0;
			tape_din <= 8'h00;
			tape_queued_addr <= 23'd0;
			pending_addr <= 23'd0;
		end
		else begin
			if (tape_wr_ack)
				tape_wr <= 1'b0;
			if ((tape_download && ioctl_wr) && (!tape_wr || tape_wr_ack)) begin
				tape_wr <= 1'b1;
				tape_din <= ioctl_dout;
				pending_addr <= ioctl_addr;
				tape_queued_addr <= ioctl_addr;
			end
			if (clear)
				tape_queued_addr <= 23'd0;
		end
endmodule
