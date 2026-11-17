// karabas: the MiSTer video mixer and aspect parts that amstrad_video_output instantiates. The
// board tops take the picture from its obs_* taps (cpc_emu vid_*) and line-double it themselves, so
// these only keep the module complete; their outputs are unused and XST removes them.

module video_mixer #(parameter LINE_LENGTH = 768, HALF_DEPTH = 0, GAMMA = 0)
(
	input CLK_VIDEO, output reg CE_PIXEL, input ce_pix, input scandoubler, input hq2x,
	inout [21:0] gamma_bus,
	input [DWIDTH:0] R, input [DWIDTH:0] G, input [DWIDTH:0] B,
	input HSync, input VSync, input HBlank, input VBlank,
	input HDMI_FREEZE, output freeze_sync,
	output reg [7:0] VGA_R, output reg [7:0] VGA_G, output reg [7:0] VGA_B,
	output reg VGA_VS, output reg VGA_HS, output reg VGA_DE
);
localparam DWIDTH = HALF_DEPTH ? 3 : 7;
assign gamma_bus = 'Z;
assign freeze_sync = 1'b0;
always @(posedge CLK_VIDEO) begin
	CE_PIXEL <= ce_pix;
	if (ce_pix) begin
		VGA_R <= R; VGA_G <= G; VGA_B <= B;
		VGA_HS <= HSync; VGA_VS <= VSync; VGA_DE <= ~(HBlank | VBlank);
	end
end
endmodule

module video_freak
(
	input CLK_VIDEO, input CE_PIXEL, input VGA_VS, input [11:0] HDMI_WIDTH, input [11:0] HDMI_HEIGHT,
	output VGA_DE, output reg [12:0] VIDEO_ARX, output reg [12:0] VIDEO_ARY,
	input VGA_DE_IN, input [11:0] ARX, input [11:0] ARY, input [11:0] CROP_SIZE,
	input [4:0] CROP_OFF, input [2:0] SCALE
);
assign VGA_DE = VGA_DE_IN;
always @(posedge CLK_VIDEO) begin VIDEO_ARX <= ARX; VIDEO_ARY <= ARY; end
endmodule
