`timescale 1ns / 1ps
// cpc_core with a model of the board SRAM (2M x 16, read without delay: the data of MA while
// /OE of a lane is low, a write of a lane while its /WE is low). sim_cpc.cpp drives the clock,
// the loads and the keys, and takes the picture.
module tb_cpc (
	input wire clk_sys,
	input wire areset,

	input wire [1:0] ld_kind,
	input wire ld_start,
	input wire ld_active,
	input wire ld_wr,
	input wire [31:0] ld_addr,
	input wire [7:0] ld_data,
	output wire ld_ready,

	input wire [7:0] ps2_code,
	input wire ps2_wr,

	input wire [1:0] sw_model,
	input wire sw_crtc,

	output wire vid_ce,
	output wire [7:0] vid_r,
	output wire [7:0] vid_g,
	output wire [7:0] vid_b,
	output wire vid_hs,
	output wire vid_vs,
	output wire vid_hbl,
	output wire vid_vbl,
	output wire loading,
	output wire [15:0] audio_l,

	// cpc_video_out of the board tops on clk_pix = clk_sys / 2 (phase aligned)
	output reg clk_pix = 1'b0,
	output wire [23:0] vo_rgb,
	output wire vo_hs,
	output wire vo_vs,
	output wire vo_de
);

wire [20:0] MA;
wire [15:0] MD_O;
wire MD_OE;
wire [1:0] MWR_N, MRD_N;

reg [15:0] mem [0:(1<<21)-1];
wire [15:0] word = mem[MA];
wire [15:0] MD_I = { MRD_N[1] ? 8'hFF : word[15:8], MRD_N[0] ? 8'hFF : word[7:0] };

always @(posedge clk_sys) begin
	if (!MWR_N[0]) mem[MA][7:0] <= MD_O[7:0];
	if (!MWR_N[1]) mem[MA][15:8] <= MD_O[15:8];
end

cpc_core core (
	.clk_sys(clk_sys),
	.locked(!areset),
	.areset(areset),
	.ld_kind(ld_kind),
	.ld_slot(8'd0),
	.ld_ext(64'd0),
	.ld_start(ld_start),
	.ld_active(ld_active),
	.ld_wr(ld_wr),
	.ld_addr(ld_addr),
	.ld_data(ld_data),
	.ld_ready(ld_ready),
	.ps2_code(ps2_code),
	.ps2_kind(1'b0),
	.ps2_wr(ps2_wr),
	.ms_x(8'd0), .ms_y(8'd0), .ms_b(8'd0), .ms_wr(1'b0),
	.joy_l(16'd0), .joy_r(16'd0),
	.sw_model(sw_model),
	.sw_crtc(sw_crtc),
	.sw_display(3'd0),
	.sw_reset(1'b0),
	.sdc_img_mounted(8'd0), .sdc_img_size(64'd0), .img_wp(8'd0), .sdc_rd(), .sdc_wr(), .sdc_sector(),
	.sdc_busy(1'b0), .sdc_done(1'b0), .sdc_slot(3'd0), .sdc_byte_in_strobe(1'b0), .sdc_byte_addr(9'd0),
	.sdc_byte_in_data(8'd0), .sdc_byte_out_data(),
	.MA(MA),
	.MD_I(MD_I),
	.MD_O(MD_O),
	.MD_OE(MD_OE),
	.MWR_N(MWR_N),
	.MRD_N(MRD_N),
	.vid_ce(vid_ce),
	.vid_r(vid_r),
	.vid_g(vid_g),
	.vid_b(vid_b),
	.vid_hs(vid_hs),
	.vid_vs(vid_vs),
	.vid_hbl(vid_hbl),
	.vid_vbl(vid_vbl),
	.audio_l(audio_l),
	.audio_r(),
	.tape_in(1'b0),
	.tape_out(),
	.led_user(),
	.loading(loading)
);

always @(posedge clk_sys)
	clk_pix <= ~clk_pix;

cpc_video_out video_out (
	.clk_sys(clk_sys), .vid_ce(vid_ce), .vid_r(vid_r), .vid_g(vid_g), .vid_b(vid_b),
	.vid_hs(vid_hs), .vid_vs(vid_vs), .vid_hbl(vid_hbl), .vid_vbl(vid_vbl),
	.clk_pix(clk_pix), .rgb(vo_rgb), .hs(vo_hs), .vs(vo_vs), .de(vo_de)
);

endmodule
