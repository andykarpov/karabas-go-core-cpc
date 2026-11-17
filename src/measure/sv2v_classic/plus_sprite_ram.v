module plus_sprite_ram (
	clk,
	reset,
	host_rd,
	host_wr,
	host_addr,
	host_wdata,
	host_rdata,
	video_rd,
	video_addr,
	video_rdata
);
	input clk;
	input reset;
	input host_rd;
	input host_wr;
	input [11:0] host_addr;
	input [3:0] host_wdata;
	output wire [3:0] host_rdata;
	input video_rd;
	input [10:0] video_addr;
	output wire [7:0] video_rdata;
	wire [3:0] host_even_q;
	wire [3:0] host_odd_q;
	wire [3:0] video_even_q;
	wire [3:0] video_odd_q;
	reg host_bank_q;
	reg host_valid_q;
	reg video_valid_q;
	wire host_rd_en = host_rd && !reset;
	wire host_wr_en = host_wr && !reset;
	wire video_rd_en = video_rd && !reset;
	assign host_rdata = (host_valid_q ? (host_bank_q ? host_odd_q : host_even_q) : 4'd0);
	assign video_rdata = (video_valid_q ? {video_odd_q, video_even_q} : 8'd0);
	initial begin
		host_bank_q = 1'b0;
		host_valid_q = 1'b0;
		video_valid_q = 1'b0;
	end
	plus_sprite_ram_bank even_bank(
		.clk(clk),
		.host_rd(host_rd_en && !host_addr[0]),
		.host_wr(host_wr_en && !host_addr[0]),
		.host_addr(host_addr[11:1]),
		.host_wdata(host_wdata),
		.host_q(host_even_q),
		.video_rd(video_rd_en),
		.video_addr(video_addr),
		.video_q(video_even_q)
	);
	plus_sprite_ram_bank odd_bank(
		.clk(clk),
		.host_rd(host_rd_en && host_addr[0]),
		.host_wr(host_wr_en && host_addr[0]),
		.host_addr(host_addr[11:1]),
		.host_wdata(host_wdata),
		.host_q(host_odd_q),
		.video_rd(video_rd_en),
		.video_addr(video_addr),
		.video_q(video_odd_q)
	);
	always @(posedge clk)
		if (reset) begin
			host_bank_q <= 1'b0;
			host_valid_q <= 1'b0;
			video_valid_q <= 1'b0;
		end
		else begin
			if (host_rd) begin
				host_bank_q <= host_addr[0];
				host_valid_q <= 1'b1;
			end
			if (video_rd)
				video_valid_q <= 1'b1;
		end
endmodule
