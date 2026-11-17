`timescale 1ns / 1ps
`default_nettype wire

/*
 Amstrad CPC core for Karabas Mini rev.G (HDMI, PCM5102): cpc_core (the CPC of the renaudguerin
 Amstrad_MiSTer fork, classic models, rtl/karabas) with the board glue of karabas-go-modules.

 Clocks (cpc_clocks): DCM_CLKGEN 64 MHz -> PLL: clk_sys 64 MHz (the machine: ce_16 = 16 MHz as on
 MiSTer, the SRAM, the MCU link, the line doubler, the DAC), clk_pix 32 MHz (phase aligned: the doubled
 picture, the OSD, HDMI), clk_hdmi / clk_hdmi_n 160 MHz (the serialiser), clk_8 8 MHz (FT_CLK_OUT).

 Memory: all of it in the SRAM (cpc_sram: the ports of the upstream sdram.v, the map in its header):
 the system ROMs come from the .kg (roms/boot.rom, 160K, as the upstream boot.rom: OS6128 + BASIC 1.1
 + AMSDOS + MF2, OS664 + BASIC664 + AMSDOS + MF2, OS464 + BASIC464) when the core starts.

 Video: the 15.625 kHz picture of the Gate Array (1024 pixels of 16 MHz a line, 312 lines) through
 scandoubler (VIC20Nano / Till Harbaum): 1024 x 624 at 32 MHz (31.25 kHz, 50.08 Hz), de the window
 of H_DE_W x V_DE_H from H_DE_X / V_DE_Y (the CPC picture with its border in the middle), the OSD of
 link v2 over it, HDMI with audio. Syncs negative.

 Audio: the AY (ABC stereo of upstream) + tape sound, to the PCM5102 and HDMI (48 kHz).

 Soft switches (the index of the item in the osd of core.json, the "index" of the items):
   0 Model (CPC 6128 / 664 / 464)   1 CRTC (Type 1 / Type 0)   2 Display (colour GA / ASIC, green,
   amber, cyan, white)   3 Reset
*/

module karabas_minig_top (
	input wire CLK_50MHZ,

	inout wire UART_RX,
	inout wire UART_TX,
	inout wire UART_CTS,

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

	input wire [7:0] VGA_R,
	input wire [7:0] VGA_G,
	input wire [7:0] VGA_B,
	input wire VGA_HS,
	input wire VGA_VS,

	output wire [3:0] TMDS_P,
	output wire [3:0] TMDS_N,

	output wire FT_SPI_CS_N,
	output wire FT_SPI_SCK,
	input wire FT_SPI_MISO,
	output wire FT_SPI_MOSI,
	input wire FT_INT_N,
	input wire FT_CLK,
	input wire FT_DE,
	output wire FT_CLK_OUT,

	output wire [2:0] WA,
	output wire [1:0] WCS_N,
	output wire WRD_N,
	output wire WWR_N,
	output wire WRESET_N,
	inout wire [15:0] WD,

	output wire TAPE_OUT,
	input wire TAPE_IN,

	output wire DAC_BCK,
	output wire DAC_WS,
	output wire DAC_DAT,

	output wire ADC_CLK,
	inout wire ADC_BCK,
	inout wire ADC_LRCK,
	input wire ADC_DOUT,

	input wire MCU_CS_N,
	input wire MCU_SCK,
	inout wire MCU_MOSI,
	output wire MCU_MISO,
	inout wire [5:0] MCU_IO, // [0] burst cs_n, [1] burst ready, [2] sd2 cs_n, [3] ft cs_n

	output wire MIDI_TX,

	output wire ESP32_SPI_CS_N,
	input wire ESP32_PCM_BCK,
	input wire ESP32_PCM_RLCK,
	input wire ESP32_PCM_DAT,

	output wire FLASH_CS_N,
	input wire FLASH_DO,
	output wire FLASH_DI,
	output wire FLASH_SCK,
	output wire FLASH_WP_N,
	output wire FLASH_HOLD_N
);

// the de window of the doubled picture (clk_pix, from the leading edge of the doubled hsync / the
// first line after the leading edge of vsync); sim/run_boot.sh --geometry: 1024 x 624, hs 64, vs 4 lines
localparam H_DE_X = 11'd203;   // the picture of the Gate Array (with its border): pixels 204..971 of the doubled line
localparam H_DE_W = 11'd768;
localparam V_DE_Y = 10'd45;    // its lines 61..605 (545) in the middle of 576
localparam V_DE_H = 10'd576;

// ------------------------------------------------------------------ unused

assign WA = 3'b000;
assign WCS_N = 2'b11;
assign WRD_N = 1'b1;
assign WWR_N = 1'b1;
assign WRESET_N = 1'b1;
assign WD = 16'bz;

assign ESP32_SPI_CS_N = 1'b1;
assign UART_RX = 1'bz;
assign UART_TX = 1'bz;
assign UART_CTS = 1'bz;

assign ADC_CLK = 1'b0;
assign ADC_BCK = 1'bz;
assign ADC_LRCK = 1'bz;
assign MIDI_TX = 1'b1;

// the SDRAM is not used: no clock, deselected by its commands (NOP: RAS / CAS / WE high)
assign SDR_A = 13'd0;
assign SDR_BA = 2'b00;
assign SDR_CLK = 1'b0;
assign SDR_DQM = 2'b11;
assign SDR_WE_N = 1'b1;
assign SDR_CAS_N = 1'b1;
assign SDR_RAS_N = 1'b1;
assign SDR_DQ = 16'bz;

// FLASH_CS_N (T3) is the SDRAM /CS of Mini G2 (rev G: tied low on the board): always selected
assign FLASH_CS_N = 1'b0;
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

// the clock of the FT812
ODDR2 oddr_ft_clk (.Q(FT_CLK_OUT), .C0(clk_8), .C1(~clk_8), .CE(1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));

// ------------------------------------------------------------------ MCU

wire mcu_sck_ibufg, mcu_sck;
IBUFG ibufg_mcu_sck (.I(MCU_SCK), .O(mcu_sck_ibufg));
BUFG bufg_mcu_sck (.I(mcu_sck_ibufg), .O(mcu_sck));

// karabas: MCU link v2 (karabas-go-firmware docs/link_v2.md, kg_mcu2); INT on IO1
wire mcu_int;
assign MCU_IO[1] = mcu_int;
assign MCU_IO[0] = 1'bz;
assign MCU_IO[5:2] = 4'bzzzz;

wire [15:0] joy_l, joy_r;
wire [7:0] ms_x, ms_y, ms_b;
wire ms_wr;
wire [7:0] ps2_code;
wire ps2_kind, ps2_wr;
wire [1:0] ld_kind;
wire [7:0] ld_slot, ld_data;
wire [31:0] ld_addr;
wire ld_active, ld_wr, ld_ready;
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
	.CAPS(16'h0010),     // bit 4: the core drives LD_READY
	.ENABLE_OSD(1),
	.ENABLE_IMG(0),
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
	.MCU_SPI_FT_SS(MCU_IO[3]),
	.MCU_SPI_SD2_SS(MCU_IO[2]),

	.SW(sw), .SW_WR(), .SW_INDEX(), .SW_VALUE(), .HW_ID(), .DVI_ONLY(dvi_only), .CORE_BUILD(), .FW_BUILD(),
	.BUSY(), .BTNS(), .RELOAD_REQ(1'b0), .RELOAD_CORE(8'd0),

	.KBD(), .KBD_WR(),
	.PS2_CODE(ps2_code), .PS2_KIND(ps2_kind), .PS2_WR(ps2_wr),
	.MS_X(ms_x), .MS_Y(ms_y), .MS_Z(), .MS_B(ms_b), .MS_WR(ms_wr),
	.JOY_L(joy_l), .JOY_R(joy_r), .JOY_WR(),
	.PS2_CMD(16'h0000), .PS2_CMD_WR(1'b0),

	.LD_KIND(ld_kind), .LD_SLOT(ld_slot), .LD_SIZE(), .LD_START(), .LD_ACTIVE(ld_active), .LD_END(),
	.LD_ADDR(ld_addr), .LD_DATA(ld_data), .LD_WR(ld_wr), .LD_READY(ld_ready),

	.OSD_WR(osd_wr), .OSD_WADDR(osd_waddr), .OSD_WDATA(osd_wdata), .OSD_EN(osd_en),
	.OSD_FG(osd_fg), .OSD_BG(osd_bg), .OSD_ALPHA(osd_alpha), .OSD_PX(osd_px), .OSD_PY(osd_py),
	.OSD_PW(osd_pw), .OSD_PH(osd_ph), .OSD_PLACE(osd_place), .OSD_ZOOM(osd_zoom),

	.SDC_IMG_MOUNTED(), .SDC_IMG_SIZE(), .SDC_RD(8'd0), .SDC_WR(8'd0), .SDC_SECTOR(32'd0), .SDC_BUSY(),
	.SDC_DONE(), .SDC_ERROR(), .SDC_SLOT(), .SDC_BYTE_IN_STROBE(), .SDC_BYTE_ADDR(), .SDC_BYTE_IN_DATA(),
	.SDC_BYTE_OUT_DATA(8'd0), .IMG_WP(), .IMG_PHYS_WR(), .IMG_PHYS(), .IMG_FLUSH(), .FDD_CHNG_WR(), .FDD_CHNG(),
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

// the line doubler: a sample of the 16 MHz picture every 4 clocks, out every 2 (32 MHz)
wire [7:0] sd_r, sd_g, sd_b;
wire sd_hs, sd_vs, sd_hb, sd_vb;
scandoubler #(.HCNT_WIDTH(11), .COLOR_DEPTH(6), .OUT_COLOR_DEPTH(8)) doubler (
	.clk_sys(clk_sys),
	.bypass(1'b0),
	.ce_divider(3'd1),
	.pixel_ena(),
	.scanlines(2'b00),
	.hb_in(vid_hbl),
	.vb_in(vid_vbl),
	.hs_in(vid_hs),
	.vs_in(vid_vs),
	.r_in(vid_r[7:2]),
	.g_in(vid_g[7:2]),
	.b_in(vid_b[7:2]),
	.hb_out(sd_hb),
	.vb_out(sd_vb),
	.hs_out(sd_hs),
	.vs_out(sd_vs),
	.r_out(sd_r),
	.g_out(sd_g),
	.b_out(sd_b)
);

// into clk_pix (phase aligned, the doubler changes its outputs every 2 clk_sys); the de window
reg [23:0] px_rgb = 24'd0;
reg px_hs = 1'b0, px_vs = 1'b0, px_hs_d = 1'b0, px_vs_d = 1'b0, vs_seen = 1'b0;
reg [10:0] hc = 11'd0;
reg [9:0] vl = 10'd0;
always @(posedge clk_pix) begin
	px_rgb <= { sd_r, sd_g, sd_b };
	px_hs <= sd_hs;
	px_vs <= sd_vs;
	px_hs_d <= px_hs;
	px_vs_d <= px_vs;
	hc <= (px_hs && !px_hs_d) ? 11'd0 : hc + 11'd1;
	if (px_vs && !px_vs_d)
		vs_seen <= 1'b1;
	if (px_hs && !px_hs_d) begin
		vl <= vs_seen ? 10'd0 : vl + 10'd1;
		vs_seen <= 1'b0;
	end
end
wire win = hc >= H_DE_X && hc < H_DE_X + H_DE_W && vl >= V_DE_Y && vl < V_DE_Y + V_DE_H;
reg [23:0] vid_rgb = 24'd0;
reg vid_hs_o = 1'b0, vid_vs_o = 1'b0, vid_de = 1'b0;   // syncs high active
always @(posedge clk_pix) begin
	vid_de <= win;
	vid_rgb <= win ? px_rgb : 24'd0;
	vid_hs_o <= px_hs;
	vid_vs_o <= px_vs;
end

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

// MiSTer audio is unsigned: the DAC and HDMI take two's complement
wire [15:0] snd_l = audio_l ^ 16'h8000;
wire [15:0] snd_r = audio_r ^ 16'h8000;

kg_pcm5102 #(.DIV_BITS(3)) dac (  // bck 4 MHz, 125 kHz
	.clk(clk_sys),
	.reset(areset),
	.left(snd_l),
	.right(snd_r),
	.din(DAC_DAT),
	.bck(DAC_BCK),
	.lrck(DAC_WS)
);

// 48 kHz for hdmi_tx on clk_pix: + 3 per clock of 32 MHz, modulo 2000 (exact)
reg [10:0] aud_acc = 11'd0;
reg aud_stb = 1'b0;
reg [23:0] hdmi_l = 24'd0, hdmi_r = 24'd0;
always @(posedge clk_pix) begin
	aud_stb <= 1'b0;
	if (aud_acc >= 11'd1997) begin
		aud_acc <= aud_acc + 11'd3 - 11'd2000;
		aud_stb <= 1'b1;
		hdmi_l <= { snd_l, 8'd0 };
		hdmi_r <= { snd_r, 8'd0 };
	end
	else
		aud_acc <= aud_acc + 11'd3;
end

// ------------------------------------------------------------------ HDMI

reg dvi_only_p = 1'b0;
always @(posedge clk_pix)
	dvi_only_p <= dvi_only;

// negative syncs
reg hdmi_hs = 1'b1, hdmi_vs = 1'b1, hdmi_de = 1'b0;
reg [23:0] hdmi_rgb = 24'd0;
always @(posedge clk_pix) begin
	hdmi_hs <= ~osd_hs;
	hdmi_vs <= ~osd_vs;
	hdmi_de <= osd_de;
	hdmi_rgb <= osd_rgb;
end

hdmi_tx #(.SAMPLE_FREQ(48000)) hdmi (
	.clk(clk_pix),
	.sclk(clk_hdmi),
	.sclk_n(clk_hdmi_n),
	.reset(areset_pix),
	.rgb(hdmi_rgb),
	.vsync(hdmi_vs),
	.hsync(hdmi_hs),
	.de(hdmi_de),
	.audio_en(~dvi_only_p),
	.audio_l(hdmi_l),
	.audio_r(hdmi_r),
	.audio_clk(aud_stb),
	.tx_clk_n(TMDS_N[3]),
	.tx_clk_p(TMDS_P[3]),
	.tx_d_n(TMDS_N[2:0]),
	.tx_d_p(TMDS_P[2:0])
);

// ------------------------------------------------------------------ debug

// DEBUG_ADDR: { loading, led_user, 12'd0, model }
assign dbg_addr = { loading, led_user, 12'd0, sw_model };
always @(posedge clk_sys)
	dbg_data <= audio_l;

endmodule
