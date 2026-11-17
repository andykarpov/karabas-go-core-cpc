module video_mixer (
	CLK_VIDEO,
	CE_PIXEL,
	ce_pix,
	scandoubler,
	hq2x,
	gamma_bus,
	R,
	G,
	B,
	HSync,
	VSync,
	HBlank,
	VBlank,
	HDMI_FREEZE,
	freeze_sync,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_VS,
	VGA_HS,
	VGA_DE
);
	parameter LINE_LENGTH = 768;
	parameter HALF_DEPTH = 0;
	parameter GAMMA = 0;
	input CLK_VIDEO;
	output reg CE_PIXEL;
	input ce_pix;
	input scandoubler;
	input hq2x;
	inout [21:0] gamma_bus;
	localparam DWIDTH = (HALF_DEPTH ? 3 : 7);
	input [DWIDTH:0] R;
	input [DWIDTH:0] G;
	input [DWIDTH:0] B;
	input HSync;
	input VSync;
	input HBlank;
	input VBlank;
	input HDMI_FREEZE;
	output wire freeze_sync;
	output reg [7:0] VGA_R;
	output reg [7:0] VGA_G;
	output reg [7:0] VGA_B;
	output reg VGA_VS;
	output reg VGA_HS;
	output reg VGA_DE;
	assign gamma_bus = 1'sbz;
	assign freeze_sync = 1'b0;
	always @(posedge CLK_VIDEO) begin
		CE_PIXEL <= ce_pix;
		if (ce_pix) begin
			VGA_R <= R;
			VGA_G <= G;
			VGA_B <= B;
			VGA_HS <= HSync;
			VGA_VS <= VSync;
			VGA_DE <= ~(HBlank | VBlank);
		end
	end
endmodule
