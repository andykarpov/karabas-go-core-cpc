`timescale 1ns / 1ps
`default_nettype wire

/*
 Amstrad CPC core for Karabas Go (VGA, PCM5102). Made by tools/mktops.py from
 karabas_minig_top.v (do not edit: change that one and run it): the same except the pins, the MCU
 link (MCU_SCK not on a clock pin) and the video: 24 bit RGB to the VGA DAC with its pixel clock on
 V_CLK (clk_pix), the FT812 off that bus (FT_OE_N = 1), no HDMI. The floppy connector is not used
 (its outputs 0).
 cpc_core (the CPC of the renaudguerin Amstrad_MiSTer fork, classic models, rtl/karabas) with the
 board glue of karabas-go-modules.

 Clocks (cpc_clocks): DCM_CLKGEN 64 MHz -> PLL: clk_sys 64 MHz (the machine: ce_16 = 16 MHz as on
 MiSTer, the SRAM, the MCU link, the line doubler, the DAC), clk_pix 32 MHz (phase aligned: the doubled
 picture, the OSD, HDMI), clk_hdmi / clk_hdmi_n 160 MHz (the serialiser), clk_8 8 MHz (FT_CLK_OUT).

 Memory: all of it in the SRAM (cpc_sram: the ports of the upstream sdram.v, the map in its header):
 the system ROMs come from the .kg (roms/boot.rom, 160K, as the upstream boot.rom: OS6128 + BASIC 1.1
 + AMSDOS + MF2, OS664 + BASIC664 + AMSDOS + MF2, OS464 + BASIC464) when the core starts.

 Video: the 15.625 kHz picture of the Gate Array (1024 pixels of 16 MHz a line, 312 lines) line-doubled
 by cpc_video_out with its own timing: 1024 x 624 at 32 MHz (31.25 kHz, 50.08 Hz), syncs and de always
 present (also in reset), de the window of H_DE_W x V_DE_H from H_DE_X / V_DE_Y (the CPC picture with
 its border in the middle), the OSD of link v2 over it, HDMI with audio. Syncs negative.

 Audio: the AY (ABC stereo of upstream) + tape sound, to the PCM5102 and HDMI (48 kHz).

 Soft switches (the index of the item in the osd of core.json, the "index" of the items):
   0 Model (CPC 6128 / 664 / 464)   1 CRTC (Type 1 / Type 0)   2 Display (colour GA / ASIC, green,
   amber, cyan, white)   3 Reset
*/

module karabas_go_top (
	input wire CLK_50MHZ,

	inout wire UART_RX,
	inout wire UART_TX,
	inout wire UART_CTS,
	inout wire ESP_RESET_N,
	inout wire ESP_BOOT_N,

	output wire [20:0] MA,
	inout wire [15:0] MD,
	output wire [1:0] MWR_N,
	output wire [1:0] MRD_N,

	output wire [1:0] SDR_BA,
	output wire [12:0] SDR_A,
	output wire SDR_CLK,
	output wire [1:0] SDR_DQM,
	output wire SDR_WE_N,
	output wire SDR_CAS_N,
	output wire SDR_RAS_N,
	inout wire [15:0] SDR_DQ,

	output wire SD_CS_N,
	output wire SD_CLK,
	output wire SD_DI,
	input wire SD_DO,
	input wire SD_DET_N,

	output wire [7:0] VGA_R,
	output wire [7:0] VGA_G,
	output wire [7:0] VGA_B,
	output wire VGA_HS,
	output wire VGA_VS,
	output wire V_CLK,

	output wire FT_SPI_CS_N,
	output wire FT_SPI_SCK,
	input wire FT_SPI_MISO,
	output wire FT_SPI_MOSI,
	input wire FT_INT_N,
	input wire FT_CLK,
	output wire FT_OE_N,

	output wire [2:0] WA,
	output wire [1:0] WCS_N,
	output wire WRD_N,
	output wire WWR_N,
	output wire WRESET_N,
	inout wire [15:0] WD,

	input wire FDC_INDEX,
	output wire [1:0] FDC_DRIVE,
	output wire FDC_MOTOR,
	output wire FDC_DIR,
	output wire FDC_STEP,
	output wire FDC_WDATA,
	output wire FDC_WGATE,
	input wire FDC_TR00,
	input wire FDC_WPRT,
	input wire FDC_RDATA,
	output wire FDC_SIDE_N,

	output wire TAPE_OUT,
	input wire TAPE_IN,
	output wire BEEPER,

	output wire DAC_LRCK,
	output wire DAC_DAT,
	output wire DAC_BCK,
	output wire DAC_MUTE,

	input wire MCU_CS_N,
	input wire MCU_SCK,
	inout wire MCU_MOSI,
	output wire MCU_MISO,
	input wire MCU_SPI_FT_CS_N,
	input wire MCU_SPI_SD2_CS_N,
	inout wire [1:0] MCU_SPI_IO, // [0] INT of link v2 (firmware IO1, GPIO2), [1] unused (IO0, GPIO14)

	output wire MIDI_TX,
	output wire MIDI_CLK,
	output wire MIDI_RESET_N,

	output wire FLASH_CS_N,
	input wire FLASH_DO,
	output wire FLASH_DI,
	output wire FLASH_SCK,
	output wire FLASH_WP_N,
	output wire FLASH_HOLD_N
);

// the de window of the doubled picture (cpc_video_out: pixels of the GA line from the rising edge of
// its hsync, output lines from the line after its vsync); sim/run_boot.sh --geometry
localparam H_DE_X = 204;   // the picture of the Gate Array with its border: pixels 204..971
localparam H_DE_W = 768;
localparam V_DE_Y = 45;    // its lines in the middle of 576
localparam V_DE_H = 576;

// ------------------------------------------------------------------ unused

assign WA = 3'b000;
assign WCS_N = 2'b11;
assign WRD_N = 1'b1;
assign WWR_N = 1'b1;
assign WRESET_N = 1'b1;
assign WD = 16'bz;

assign UART_RX = 1'bz;
assign UART_TX = 1'bz;
assign UART_CTS = 1'bz;

assign FT_OE_N = 1'b1;     // the FT812 does not drive the video DAC
assign BEEPER = 1'b0;
assign DAC_MUTE = 1'b1;    // soft mute of the PCM5102: 1 = sound on

// the floppy connector is not used: its outputs 0 (the board inverts them: high = active)
assign FDC_DRIVE = 2'b00;
assign FDC_MOTOR = 1'b0;
assign FDC_DIR = 1'b0;
assign FDC_STEP = 1'b0;
assign FDC_WDATA = 1'b0;
assign FDC_WGATE = 1'b0;
assign FDC_SIDE_N = 1'b0;
assign MIDI_TX = 1'b1;
assign ESP_RESET_N = 1'bz;
assign ESP_BOOT_N = 1'bz;
assign MIDI_CLK = 1'b0;      // the SAM2695 synth: held in reset, not used
assign MIDI_RESET_N = 1'b0;

// the SDRAM is not used: no clock, deselected by its commands (NOP: RAS / CAS / WE high)
assign SDR_A = 13'd0;
assign SDR_BA = 2'b00;
assign SDR_CLK = 1'b0;
assign SDR_DQM = 2'b11;
assign SDR_WE_N = 1'b1;
assign SDR_CAS_N = 1'b1;
assign SDR_RAS_N = 1'b1;
assign SDR_DQ = 16'bz;

// the flash chip (the SDRAM /CS is hard wired on Go): not selected
assign FLASH_CS_N = 1'b1;
assign FLASH_DI = 1'b1;
assign FLASH_SCK = 1'b0;
assign FLASH_WP_N = 1'b1;
assign FLASH_HOLD_N = 1'b1;

// ------------------------------------------------------------------ clocks

wire clk_sys, clk_pix, clk_hdmi, clk_hdmi_n, clk_8, pll_locked;
cpc_clocks clocks (
	.clk_in(CLK_50MHZ),
	.clk_sys(clk_sys),
	.clk_pix(clk_pix),
	.clk_hdmi(clk_hdmi),
	.clk_hdmi_n(clk_hdmi_n),
	.clk_8(clk_8),
	.locked(pll_locked)
);
(* KEEP = "TRUE" *) wire areset_async = ~pll_locked;
// the reset in each clock: synchronised (the locked flag of the PLL is not of these clocks; the ucf takes
// the path into the first stage out of the timing)
wire areset, areset_pix;
kg_sync #(.W(1), .STAGES(2), .INIT(1'b1)) sync_areset (.clk(clk_sys), .d(areset_async), .q(areset));
kg_sync #(.W(1), .STAGES(2), .INIT(1'b1)) sync_areset_pix (.clk(clk_pix), .d(areset_async), .q(areset_pix));

// the pixel clock of the VGA DAC, inverted: the DAC takes the pixel on the rising V_CLK, the middle of the pixel
ODDR2 oddr_v_clk (.Q(V_CLK), .C0(clk_pix), .C1(~clk_pix), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0));

// ------------------------------------------------------------------ MCU

// MCU_SCK is not on a clock pin before rev.G (CLOCK_DEDICATED_ROUTE = FALSE in the ucf)
wire mcu_sck = MCU_SCK, mcu_sck_ibufg = MCU_SCK;

// karabas: MCU link v2 (karabas-go-firmware docs/link_v2.md, kg_mcu2); INT on IO1
wire mcu_int;
assign MCU_SPI_IO[0] = mcu_int;   // INT of link v2 on N9 (IO1 of the firmware)
assign MCU_SPI_IO[1] = 1'bz;

wire [15:0] joy_l, joy_r;
wire [7:0] ms_x, ms_y, ms_b;
wire ms_wr;
wire [7:0] ps2_code;
wire ps2_kind, ps2_wr;
wire [1:0] ld_kind;
wire [7:0] ld_slot, ld_data;
wire [31:0] ld_addr;
wire [63:0] ld_ext;
wire ld_start, ld_active, ld_wr, ld_ready;
wire [7:0] sdc_img_mounted, img_wp, sdc_rd, sdc_wr, sdc_byte_in_data, sdc_byte_out_data;
wire [63:0] sdc_img_size;
wire [31:0] sdc_sector;
wire sdc_busy, sdc_done, sdc_byte_in_strobe;
wire [2:0] sdc_slot;
wire [8:0] sdc_byte_addr;
wire [8*8-1:0] sw;
wire dvi_only;
wire ft_cs_n, ft_mosi, ft_spi_on, sd2_cs_n, sd2_mosi;
wire [15:0] dbg_addr;
reg [15:0] dbg_data = 16'd0;
wire osd_wr, osd_en, osd_zoom;
wire [11:0] osd_waddr;
wire [7:0] osd_wdata;
wire [23:0] osd_fg, osd_bg;
wire [1:0] osd_alpha, osd_place;
wire [4:0] osd_px, osd_ph;
wire [3:0] osd_py;
wire [5:0] osd_pw;

kg_mcu2 #(
	.SW_N(8),
	.CS_FILTER(3),
	.CAPS(16'h0014),     // bit 4: the core drives LD_READY, bit 2: write protected images
	.ENABLE_OSD(1),
	.ENABLE_IMG(1),
	.IMG_OUT_LATENCY(3), // the address register of kg_l2_img, sd_buff_din of u765 (BRAM), the register of cpc_sd_sdc (2 wrote each byte one place later on the board)
	.ENABLE_AUX(1),      // DEBUG_*: the state of the core (AT+KARABAS=debug:1, kg_board.py log)
	.ENABLE_FT(1),
	.ENABLE_SD2(1)
) mcu (
	.CLK(clk_sys),
	.N_RESET(~areset),

	.MCU_SCK(mcu_sck),
	.MCU_MOSI(MCU_MOSI),
	.MCU_MISO(MCU_MISO),
	.MCU_SS(MCU_CS_N),
	.MCU_INT(mcu_int),
	.MCU_SPI_FT_SS(MCU_SPI_FT_CS_N),
	.MCU_SPI_SD2_SS(MCU_SPI_SD2_CS_N),

	.SW(sw), .SW_WR(), .SW_INDEX(), .SW_VALUE(), .HW_ID(), .DVI_ONLY(dvi_only), .CORE_BUILD(), .FW_BUILD(),
	.BUSY(), .BTNS(), .RELOAD_REQ(1'b0), .RELOAD_CORE(8'd0),

	.KBD(), .KBD_WR(),
	.PS2_CODE(ps2_code), .PS2_KIND(ps2_kind), .PS2_WR(ps2_wr),
	.MS_X(ms_x), .MS_Y(ms_y), .MS_Z(), .MS_B(ms_b), .MS_WR(ms_wr),
	.JOY_L(joy_l), .JOY_R(joy_r), .JOY_WR(),
	.PS2_CMD(16'h0000), .PS2_CMD_WR(1'b0),

	.LD_KIND(ld_kind), .LD_SLOT(ld_slot), .LD_SIZE(), .LD_EXT(ld_ext), .LD_START(ld_start), .LD_ACTIVE(ld_active), .LD_END(),
	.LD_ADDR(ld_addr), .LD_DATA(ld_data), .LD_WR(ld_wr), .LD_READY(ld_ready),

	.OSD_WR(osd_wr), .OSD_WADDR(osd_waddr), .OSD_WDATA(osd_wdata), .OSD_EN(osd_en),
	.OSD_FG(osd_fg), .OSD_BG(osd_bg), .OSD_ALPHA(osd_alpha), .OSD_PX(osd_px), .OSD_PY(osd_py),
	.OSD_PW(osd_pw), .OSD_PH(osd_ph), .OSD_PLACE(osd_place), .OSD_ZOOM(osd_zoom),

	.SDC_IMG_MOUNTED(sdc_img_mounted), .SDC_IMG_SIZE(sdc_img_size), .SDC_RD(sdc_rd), .SDC_WR(sdc_wr),
	.SDC_SECTOR(sdc_sector), .SDC_BUSY(sdc_busy), .SDC_DONE(sdc_done), .SDC_ERROR(), .SDC_SLOT(sdc_slot),
	.SDC_BYTE_IN_STROBE(sdc_byte_in_strobe), .SDC_BYTE_ADDR(sdc_byte_addr), .SDC_BYTE_IN_DATA(sdc_byte_in_data),
	.SDC_BYTE_OUT_DATA(sdc_byte_out_data), .IMG_WP(img_wp), .IMG_PHYS_WR(), .IMG_PHYS(), .IMG_FLUSH(), .FDD_CHNG_WR(), .FDD_CHNG(),
	.FDD_CHNG_REQ(1'b0), .FDD_CHNG_DS(2'd0), .IMG_ACTIVE(),
	.PORT_OUT_DATA(), .PORT_OUT_WR(), .PORT_OUT_READY(4'b1111), .PORT_IN_DATA(32'd0), .PORT_IN_WR(4'd0),
	.PORT_CFG(128'd0), .PORT_IN_FULL(), .PORT_STAT(), .PORT_STAT_WR(),
	.RTC_A(8'd0), .RTC_DI(8'd0), .RTC_CS(1'b0), .RTC_WR_N(1'b1), .MATRIX_CMD(24'd0), .MATRIX_CMD_WR(1'b0),
	.DEBUG_ADDR(dbg_addr), .DEBUG_DATA(dbg_data), .RTC_DO(),

	.FT_SPI_ON(ft_spi_on), .FT_VGA_ON(), .FT_RESET(), .FT_SCK(), .FT_MOSI(ft_mosi), .FT_MISO(FT_SPI_MISO),
	.FT_CS_N(ft_cs_n),
	.SD2_SCK(), .SD2_MOSI(sd2_mosi), .SD2_MISO(SD_DO), .SD2_CS_N(sd2_cs_n)
);

assign FT_SPI_CS_N = ft_spi_on ? ft_cs_n : 1'b1;
assign FT_SPI_SCK = ft_spi_on ? mcu_sck_ibufg : 1'b1;
assign FT_SPI_MOSI = ft_spi_on ? ft_mosi : 1'b1;
assign SD_CS_N = sd2_cs_n;
assign SD_DI = sd2_mosi;
assign SD_CLK = mcu_sck_ibufg;

// ------------------------------------------------------------------ soft switches

wire [1:0] sw_model = sw[0*8 +: 2];
wire sw_crtc = sw[1*8];
wire [2:0] sw_display = sw[2*8 +: 3];
wire sw_reset = sw[3*8];

// ------------------------------------------------------------------ the core (cpc_core)

wire [15:0] sram_md_o;
wire sram_md_oe;
wire vid_ce, vid_hs, vid_vs, vid_hbl, vid_vbl;
wire [7:0] vid_r, vid_g, vid_b;
wire [15:0] audio_l, audio_r;
wire tape_out, led_user, loading;

reg [1:0] tape_in_s = 2'b00;
always @(posedge clk_sys)
	tape_in_s <= { tape_in_s[0], TAPE_IN };

cpc_core core (
	.clk_sys(clk_sys),
	.locked(pll_locked),
	.areset(areset),
	.ld_kind(ld_kind),
	.ld_slot(ld_slot),
	.ld_ext(ld_ext),
	.ld_start(ld_start),
	.ld_active(ld_active),
	.ld_wr(ld_wr),
	.ld_addr(ld_addr),
	.ld_data(ld_data),
	.ld_ready(ld_ready),
	.ps2_code(ps2_code),
	.ps2_kind(ps2_kind),
	.ps2_wr(ps2_wr),
	.ms_x(ms_x),
	.ms_y(ms_y),
	.ms_b(ms_b),
	.ms_wr(ms_wr),
	.joy_l(joy_l),
	.joy_r(joy_r),
	.sw_model(sw_model),
	.sw_crtc(sw_crtc),
	.sw_display(sw_display),
	.sw_reset(sw_reset),
	.sdc_img_mounted(sdc_img_mounted),
	.sdc_img_size(sdc_img_size),
	.img_wp(img_wp),
	.sdc_rd(sdc_rd),
	.sdc_wr(sdc_wr),
	.sdc_sector(sdc_sector),
	.sdc_busy(sdc_busy),
	.sdc_done(sdc_done),
	.sdc_slot(sdc_slot),
	.sdc_byte_in_strobe(sdc_byte_in_strobe),
	.sdc_byte_addr(sdc_byte_addr),
	.sdc_byte_in_data(sdc_byte_in_data),
	.sdc_byte_out_data(sdc_byte_out_data),
	.MA(MA),
	.MD_I(MD),
	.MD_O(sram_md_o),
	.MD_OE(sram_md_oe),
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
	.audio_r(audio_r),
	.tape_in(tape_in_s[1]),
	.tape_out(tape_out),
	.led_user(led_user),
	.loading(loading)
);

assign MD = sram_md_oe ? sram_md_o : 16'bz;
assign TAPE_OUT = tape_out;

// ------------------------------------------------------------------ video

// the line-doubled picture with its own timing (syncs and de always present, cpc_video_out):
// 1024 x 624 on clk_pix, de the window of the picture with its border
wire [23:0] vid_rgb;
wire vid_hs_o, vid_vs_o, vid_de;
cpc_video_out #(.H_DE_X(H_DE_X), .H_DE_W(H_DE_W), .V_DE_Y(V_DE_Y), .V_DE_H(V_DE_H)) video_out (
	.clk_sys(clk_sys),
	.vid_ce(vid_ce),
	.vid_r(vid_r),
	.vid_g(vid_g),
	.vid_b(vid_b),
	.vid_hs(vid_hs),
	.vid_vs(vid_vs),
	.vid_hbl(vid_hbl),
	.vid_vbl(vid_vbl),
	.clk_pix(clk_pix),
	.rgb(vid_rgb),
	.hs(vid_hs_o),
	.vs(vid_vs_o),
	.de(vid_de)
);

// the bitmap OSD of link v2 (kg_l2_osd_overlay): centred in de, the scale from its size,
// 2 clocks of latency with its syncs and de
wire [23:0] osd_rgb;
wire osd_hs, osd_vs, osd_de;
kg_l2_osd_overlay osd (
	.wclk(clk_sys),
	.osd_wr(osd_wr), .osd_waddr(osd_waddr), .osd_wdata(osd_wdata), .osd_en(osd_en),
	.osd_fg(osd_fg), .osd_bg(osd_bg), .osd_alpha(osd_alpha), .osd_px(osd_px), .osd_py(osd_py),
	.osd_pw(osd_pw), .osd_ph(osd_ph), .osd_place(osd_place), .osd_zoom(osd_zoom),
	.icon_on(8'd0), .icon_act(8'd0),
	.clk(clk_pix),
	.rgb_i(vid_rgb), .hs_i(vid_hs_o), .vs_i(vid_vs_o), .de_i(vid_de),
	.rgb_o(osd_rgb), .hs_o(osd_hs), .vs_o(osd_vs), .de_o(osd_de)
);

// ------------------------------------------------------------------ audio

// MiSTer audio is unsigned with silence at 0 (AUDIO_S = 0): halved, as a positive two's complement
// value (an XOR 8000 made silence -32768, a full scale DC: build 26111703)
wire [15:0] snd_l = { 1'b0, audio_l[15:1] };
wire [15:0] snd_r = { 1'b0, audio_r[15:1] };

kg_pcm5102 #(.DIV_BITS(3)) dac (  // bck 4 MHz, 125 kHz
	.clk(clk_sys),
	.reset(areset),
	.left(snd_l),
	.right(snd_r),
	.din(DAC_DAT),
	.bck(DAC_BCK),
	.lrck(DAC_LRCK)
);

// ------------------------------------------------------------------ VGA

// 1024 x 624 at 50 Hz (31.25 kHz): negative syncs as on HDMI, black outside de (the DAC has no blank
// input); the OSD output is registered with them
reg vga_hs = 1'b1, vga_vs = 1'b1;
reg [23:0] vga_rgb = 24'd0;
always @(posedge clk_pix) begin
	vga_hs <= ~osd_hs;
	vga_vs <= ~osd_vs;
	vga_rgb <= osd_de ? osd_rgb : 24'd0;
end
assign VGA_R = vga_rgb[23:16];
assign VGA_G = vga_rgb[15:8];
assign VGA_B = vga_rgb[7:0];
assign VGA_HS = vga_hs;
assign VGA_VS = vga_vs;

// ------------------------------------------------------------------ debug

// DEBUG_ADDR: { loading, led_user, 12'd0, model }
assign dbg_addr = { loading, led_user, 12'd0, sw_model };
always @(posedge clk_sys)
	dbg_data <= audio_l;

endmodule
