module video_freak (
	CLK_VIDEO,
	CE_PIXEL,
	VGA_VS,
	HDMI_WIDTH,
	HDMI_HEIGHT,
	VGA_DE,
	VIDEO_ARX,
	VIDEO_ARY,
	VGA_DE_IN,
	ARX,
	ARY,
	CROP_SIZE,
	CROP_OFF,
	SCALE
);
	input CLK_VIDEO;
	input CE_PIXEL;
	input VGA_VS;
	input [11:0] HDMI_WIDTH;
	input [11:0] HDMI_HEIGHT;
	output wire VGA_DE;
	output reg [12:0] VIDEO_ARX;
	output reg [12:0] VIDEO_ARY;
	input VGA_DE_IN;
	input [11:0] ARX;
	input [11:0] ARY;
	input [11:0] CROP_SIZE;
	input [4:0] CROP_OFF;
	input [2:0] SCALE;
	assign VGA_DE = VGA_DE_IN;
	always @(posedge CLK_VIDEO) begin
		VIDEO_ARX <= ARX;
		VIDEO_ARY <= ARY;
	end
endmodule
