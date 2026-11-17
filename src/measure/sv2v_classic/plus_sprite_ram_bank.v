module plus_sprite_ram_bank (
	clk,
	host_rd,
	host_wr,
	host_addr,
	host_wdata,
	host_q,
	video_rd,
	video_addr,
	video_q
);
	input clk;
	input host_rd;
	input host_wr;
	input [10:0] host_addr;
	input [3:0] host_wdata;
	output wire [3:0] host_q;
	input video_rd;
	input [10:0] video_addr;
	output wire [3:0] video_q;
	reg [3:0] mem [0:2047];
	reg [3:0] host_q_sim;
	reg [3:0] video_q_sim;
	assign host_q = host_q_sim;
	assign video_q = video_q_sim;
	integer i;
	initial begin
		for (i = 0; i < 2048; i = i + 1)
			mem[i] = 4'd0;
		host_q_sim = 4'd0;
		video_q_sim = 4'd0;
	end
	always @(posedge clk) begin
		if (host_rd)
			host_q_sim <= mem[host_addr];
		if (host_wr)
			mem[host_addr] <= host_wdata;
	end
	always @(posedge clk)
		if (video_rd)
			video_q_sim <= mem[video_addr];
endmodule
