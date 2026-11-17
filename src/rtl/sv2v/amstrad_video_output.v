`default_nettype wire
module amstrad_video_output (
	CLK_VIDEO,
	ce_16,
	raw_crt,
	pixel_vblank,
	plus_mode,
	mode,
	scale,
	ar,
	integer_scale,
	mix,
	r4,
	g4,
	b4,
	hs,
	vs,
	hbl,
	vbl,
	pixel_rate_select,
	forced_scandoubler,
	field_in,
	vcrop_en,
	HDMI_WIDTH,
	HDMI_HEIGHT,
	HDMI_FREEZE,
	progress_pix,
	gamma_bus,
	CE_PIXEL,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_HS,
	VGA_VS,
	VGA_DE,
	VGA_SL,
	VIDEO_ARX,
	VIDEO_ARY,
	en270p,
	obs_ce_pix,
	obs_r,
	obs_g,
	obs_b,
	obs_hs,
	obs_vs,
	obs_hbl,
	obs_vbl,
	obs_field,
	obs_native_cadence,
	obs_applied_config
);
	input CLK_VIDEO;
	input ce_16;
	input raw_crt;
	input pixel_vblank;
	input plus_mode;
	input [1:0] mode;
	input [1:0] scale;
	input [1:0] ar;
	input [1:0] integer_scale;
	input [2:0] mix;
	input [3:0] r4;
	input [3:0] g4;
	input [3:0] b4;
	input hs;
	input vs;
	input hbl;
	input vbl;
	input pixel_rate_select;
	input forced_scandoubler;
	input field_in;
	input vcrop_en;
	input [11:0] HDMI_WIDTH;
	input [11:0] HDMI_HEIGHT;
	input HDMI_FREEZE;
	input progress_pix;
	inout [21:0] gamma_bus;
	output wire CE_PIXEL;
	output wire [7:0] VGA_R;
	output wire [7:0] VGA_G;
	output wire [7:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire VGA_DE;
	output wire [1:0] VGA_SL;
	output wire [12:0] VIDEO_ARX;
	output wire [12:0] VIDEO_ARY;
	output reg en270p;
	output wire obs_ce_pix;
	output wire [7:0] obs_r;
	output wire [7:0] obs_g;
	output wire [7:0] obs_b;
	output wire obs_hs;
	output wire obs_vs;
	output wire obs_hbl;
	output wire obs_vbl;
	output wire obs_field;
	output wire obs_native_cadence;
	output wire [7:0] obs_applied_config;
	wire ce_pix;
	wire [7:0] B;
	wire [7:0] G;
	wire [7:0] R;
	wire HSync;
	wire VSync;
	wire HBlank;
	wire VBlank;
	wire hq2x = (scale == 1) & ~raw_crt;
	amstrad_video_color video_color(
		.CLK_VIDEO(CLK_VIDEO),
		.ce_16(ce_16),
		.hq2x(hq2x),
		.pixel_rate_select(pixel_rate_select & ~raw_crt),
		.pixel_vblank(pixel_vblank),
		.plus_mode(plus_mode),
		.mode(mode),
		.mix(mix),
		.r4(r4),
		.g4(g4),
		.b4(b4),
		.hs(hs),
		.vs(vs),
		.hbl(hbl),
		.vbl(vbl),
		.ce_pix(ce_pix),
		.R_out(R),
		.G_out(G),
		.B_out(B),
		.HSync(HSync),
		.VSync(VSync),
		.HBlank(HBlank),
		.VBlank(VBlank)
	);
	assign obs_ce_pix = ce_pix;
	assign obs_r = R;
	assign obs_g = G;
	assign obs_b = B;
	assign obs_hs = HSync;
	assign obs_vs = VSync;
	assign obs_hbl = HBlank;
	assign obs_vbl = VBlank;
	reg obs_field_r = 1'b0;
	always @(posedge CLK_VIDEO)
		if (ce_pix)
			obs_field_r <= field_in;
	assign obs_field = obs_field_r;
	assign obs_native_cadence = ~((pixel_rate_select | (scale == 2'd1)) | raw_crt);
	assign obs_applied_config = {plus_mode, mix, hq2x, pixel_rate_select, raw_crt, obs_native_cadence};
	assign VGA_SL = (scale[1] & ~raw_crt ? scale : 2'b00);
	wire [2:0] interlace;
	wire scandoubler_hist;
	wire scandoubler_en = scandoubler_hist & ~raw_crt;
	video_interlace interlace_hist(
		.clk(CLK_VIDEO),
		.vsync_in(vs),
		.field_in(field_in),
		.scale(scale),
		.forced_scandoubler(forced_scandoubler & ~raw_crt),
		.interlace(interlace),
		.scandoubler(scandoubler_hist)
	);
	wire vga_de;
	video_mixer #(
		.LINE_LENGTH(800),
		.GAMMA(1)
	) video_mixer(
		.CLK_VIDEO(CLK_VIDEO),
		.CE_PIXEL(CE_PIXEL),
		.ce_pix(ce_pix),
		.hq2x(hq2x),
		.gamma_bus(gamma_bus),
		.HSync(HSync),
		.VSync(VSync),
		.HBlank(HBlank),
		.VBlank(VBlank),
		.HDMI_FREEZE(HDMI_FREEZE),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_VS(VGA_VS),
		.VGA_HS(VGA_HS),
		.R(R | {8 {progress_pix}}),
		.G(G | {8 {progress_pix}}),
		.B(B | {8 {progress_pix}}),
		.VGA_DE(vga_de),
		.freeze_sync(),
		.scandoubler(scandoubler_en)
	);
	always @(posedge CLK_VIDEO) en270p <= (((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080)) && !forced_scandoubler) && !scale;
	wire vga_de_cropped;
	video_freak video_freak(
		.CLK_VIDEO(CLK_VIDEO),
		.CE_PIXEL(CE_PIXEL),
		.VGA_VS(VGA_VS),
		.HDMI_WIDTH(HDMI_WIDTH),
		.HDMI_HEIGHT(HDMI_HEIGHT),
		.VIDEO_ARX(VIDEO_ARX),
		.VIDEO_ARY(VIDEO_ARY),
		.VGA_DE(vga_de_cropped),
		.VGA_DE_IN(vga_de),
		.ARX((!ar ? 12'd4 : ar - 1'd1)),
		.ARY((!ar ? 12'd3 : 12'd0)),
		.CROP_SIZE(((en270p & vcrop_en) & ~raw_crt ? 10'd270 : 10'd0)),
		.CROP_OFF(0),
		.SCALE(integer_scale)
	);
	assign VGA_DE = (raw_crt ? vga_de : vga_de_cropped);
endmodule
