`timescale 1ns / 1ps
`default_nettype wire
/*
 cpc_video_out.v

 The 15.625 kHz picture of the Gate Array (vid_*, 16 MHz pixels at vid_ce, 1024 a line, 312 lines)
 as a line-doubled picture with its own timing: 1024 x 624 at 32 MHz (31.25 kHz, 50.08 Hz) on
 clk_pix, syncs and de ALWAYS present (also while the machine is held in reset or its CRTC is not
 programmed: the boards' monitors and the OSD need them).

 Input (clk_sys): each line of the Gate Array goes into one of two line buffers (18-bit colour, black
 in its blanking), address = the pixel since the rising edge of vid_hs; at that edge the buffers swap.
 Output (clk_pix, phase aligned): hc 0..1023 and vl 0..V_TOTAL-1 run free; the swap (an input line
 is complete) restarts hc at 0, so the output follows the input lines (every input line = two output
 lines from the line just completed); the rising edge of vid_vs sets vl to 0 at the next restart.
 Without input lines the counters wrap by themselves.

 Out (clk_pix, 2 clocks after hc): rgb, hs (hc 0..63), vs (vl 0..3), de (the window H_DE_X..+H_DE_W
 of the picture pixels, V_DE_Y..+V_DE_H lines), all high active.
*/
module cpc_video_out #(
	parameter H_DE_X = 204,      // the first pixel of the window: pixel 204 of the GA line
	parameter H_DE_W = 768,
	parameter V_DE_Y = 45,
	parameter V_DE_H = 576,
	parameter V_TOTAL = 624
) (
	input wire clk_sys,
	input wire vid_ce,
	input wire [7:0] vid_r,
	input wire [7:0] vid_g,
	input wire [7:0] vid_b,
	input wire vid_hs,
	input wire vid_vs,
	input wire vid_hbl,
	input wire vid_vbl,

	input wire clk_pix,
	output reg [23:0] rgb = 24'd0,
	output reg hs = 1'b0,
	output reg vs = 1'b0,
	output reg de = 1'b0
);

// ------------------------------------------------------------------ input (clk_sys)

reg [10:0] in_hc = 11'd0;
reg in_line = 1'b0;          // the buffer being written
reg done_line = 1'b0;        // the buffer of the last complete line
reg hs_tgl = 1'b0, vs_tgl = 1'b0;
reg in_hs_d = 1'b0, in_vs_d = 1'b0;
reg wr = 1'b0;
reg [10:0] waddr = 11'd0;
reg [17:0] wdata = 18'd0;

always @(posedge clk_sys) begin
	wr <= 1'b0;
	if (vid_ce) begin
		in_hs_d <= vid_hs;
		in_vs_d <= vid_vs;
		if (vid_hs && !in_hs_d) begin
			in_hc <= 11'd1;
			done_line <= in_line;
			in_line <= ~in_line;
			hs_tgl <= ~hs_tgl;
		end
		else if (!in_hc[10])
			in_hc <= in_hc + 11'd1;
		if (vid_vs && !in_vs_d)
			vs_tgl <= ~vs_tgl;
		wr <= !in_hc[10] && !(vid_hs && !in_hs_d);
		waddr <= { (vid_hs && !in_hs_d) ? ~in_line : in_line, (vid_hs && !in_hs_d) ? 10'd0 : in_hc[9:0] };
		wdata <= (vid_hbl || vid_vbl) ? 18'd0 : { vid_r[7:2], vid_g[7:2], vid_b[7:2] };
	end
end

wire [17:0] rdata;
reg [10:0] raddr = 11'd0;
kg_sdpram #(.DW(18), .AW(11)) linebuf (
	.clka(clk_sys),
	.wea(wr),
	.addra(waddr),
	.dina(wdata),
	.clkb(clk_pix),
	.enb(1'b1),
	.addrb(raddr),
	.doutb(rdata)
);

// ------------------------------------------------------------------ output (clk_pix)

// the toggles and done_line hold for a whole input line: two registers into clk_pix are enough
reg [2:0] hs_s = 3'd0, vs_s = 3'd0;
reg [1:0] dl_s = 2'd0;
reg [10:0] hc = 11'd0;
reg [9:0] vl = 10'd0;
reg vs_pend = 1'b0;
reg rd_line = 1'b0;

wire restart = hs_s[2] != hs_s[1];

always @(posedge clk_pix) begin
	hs_s <= { hs_s[1:0], hs_tgl };
	vs_s <= { vs_s[1:0], vs_tgl };
	dl_s <= { dl_s[0], done_line };
	if (vs_s[2] != vs_s[1])
		vs_pend <= 1'b1;

	if (restart || hc == 11'd1023) begin
		hc <= 11'd0;
		if (restart) begin
			rd_line <= dl_s[1];
			if (vs_pend) begin
				vl <= 10'd0;
				vs_pend <= 1'b0;
			end
			else
				vl <= (vl == V_TOTAL - 1) ? 10'd0 : vl + 10'd1;
		end
		else
			vl <= (vl == V_TOTAL - 1) ? 10'd0 : vl + 10'd1;
	end
	else
		hc <= hc + 11'd1;
	raddr <= { rd_line, hc[9:0] };
end

// the word of raddr comes a clock after it: the pixel and its position 2 clocks after hc
reg [10:0] hc1 = 11'd0, hc2 = 11'd0;
reg [9:0] vl1 = 10'd0, vl2 = 10'd0;
always @(posedge clk_pix) begin
	hc1 <= hc;
	vl1 <= vl;
	hc2 <= hc1;
	vl2 <= vl1;
	hs <= hc2 < 11'd64;
	vs <= vl2 < 10'd4;
	de <= hc2 >= H_DE_X && hc2 < H_DE_X + H_DE_W && vl2 >= V_DE_Y && vl2 < V_DE_Y + V_DE_H;
	rgb <= (hc2 >= H_DE_X && hc2 < H_DE_X + H_DE_W && vl2 >= V_DE_Y && vl2 < V_DE_Y + V_DE_H) ?
		{ rdata[17:12], rdata[17:16], rdata[11:6], rdata[11:10], rdata[5:0], rdata[5:4] } : 24'd0;
end

endmodule
