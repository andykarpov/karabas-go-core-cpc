// Ф0 fit measurement only (make measure-xst): stand-ins for the MiSTer framework parts that
// the emu module of upstream Amstrad.sv instantiates. Every output comes from one long shift
// register fed by HPS_BUS[0], so XST cannot treat the menu status, the downloads or the disk
// interface as constants and trim the logic behind them (the Plus path, the loaders, u765).
// The inputs are folded into HPS_BUS[1] so the logic that drives them stays too.
// Not part of the core: the board tops replace all of this with the kg_* modules.

module hps_io #(parameter CONF_STR = "", CONF_STR_BRAM = 0, PS2DIV = 0, WIDE = 0, VDNUM = 1,
                BLKSZ = 2, PS2WE = 0, STRLEN = 1, F12KEYMOD = 0)
(
	input             clk_sys,
	inout      [45:0] HPS_BUS,
	output     [31:0] joystick_0,
	output     [31:0] joystick_1,
	output     [10:0] ps2_key,
	output     [24:0] ps2_mouse,
	output      [1:0] buttons,
	output            forced_scandoubler,
	inout      [21:0] gamma_bus,
	output    [127:0] status,
	input     [127:0] status_in,
	input             status_set,
	input      [15:0] status_menumask,
	input             info_req,
	input       [7:0] info,
	output [VDNUM-1:0] img_mounted,
	output            img_readonly,
	output     [63:0] img_size,
	input      [31:0] sd_lba[VDNUM],
	input [VDNUM-1:0] sd_rd,
	input [VDNUM-1:0] sd_wr,
	output [VDNUM-1:0] sd_ack,
	output     [13:0] sd_buff_addr,
	output      [7:0] sd_buff_dout,
	input       [7:0] sd_buff_din[VDNUM],
	output            sd_buff_wr,
	output            ioctl_download,
	output     [15:0] ioctl_index,
	output            ioctl_wr,
	output     [26:0] ioctl_addr,
	output      [7:0] ioctl_dout,
	output     [31:0] ioctl_file_ext,
	input             ioctl_wait
);

localparam N = 32+32+11+25+2+1+128+VDNUM+1+64+VDNUM+14+8+1+1+16+1+27+8+32;
reg [N-1:0] sr;
always @(posedge clk_sys) sr <= {sr[N-2:0], HPS_BUS[0]};

assign {joystick_0, joystick_1, ps2_key, ps2_mouse, buttons, forced_scandoubler, status,
        img_mounted, img_readonly, img_size, sd_ack, sd_buff_addr, sd_buff_dout, sd_buff_wr,
        ioctl_download, ioctl_index, ioctl_wr, ioctl_addr, ioctl_dout, ioctl_file_ext} = sr;

integer i;
reg fold;
always @(posedge clk_sys) begin
	fold = ^status_in ^ status_set ^ ^status_menumask ^ info_req ^ ^info ^ ^sd_rd ^ ^sd_wr ^ ioctl_wait;
	for (i = 0; i < VDNUM; i = i + 1) fold = fold ^ ^sd_lba[i] ^ ^sd_buff_din[i];
end
assign HPS_BUS[1] = fold;
assign HPS_BUS[45:2] = 'Z;
assign gamma_bus = 'Z;

endmodule

module pll (input refclk, input rst, output outclk_0, output locked);
assign outclk_0 = refclk;
assign locked = ~rst;
endmodule

module ltc2308_tape #(parameter HIST_LOW = 16, HIST_HIGH = 64, ADC_RATE = 48000, CLK_RATE = 50000000, NUM_CH = 1)
(
	input reset, input clk, inout [3:0] ADC_BUS,
	output reg dout, output active, output adc_sync, output [(NUM_CH*12)-1:0] adc_data
);
always @(posedge clk) dout <= ADC_BUS[0];
assign active = ADC_BUS[1];
assign adc_sync = ADC_BUS[2];
assign adc_data = {(NUM_CH*12){ADC_BUS[3]}};
endmodule

// Our boards scan-double / scale in their own video chain: the mixer is a registered pass-through.
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

// The Cyclone V DDR output of rtl/amstrad/sdram.v (SDRAM_CLK): the board tops use ODDR2.
module altddio_out #(parameter extend_oe_disable = "OFF", intended_device_family = "", invert_output = "OFF",
                     lpm_hint = "", lpm_type = "", oe_reg = "", power_up_high = "OFF", width = 1)
(
	input [width-1:0] datain_h, input [width-1:0] datain_l, input outclock, output [width-1:0] dataout,
	input aclr, input aset, input oe, input outclocken, input sclr, input sset
);
assign dataout = outclock ? datain_h : datain_l;
endmodule
