`default_nettype wire
module Amstrad_motherboard (
	reset,
	clk,
	ce_16,
	plus_mode,
	plus_unlocked,
	plus_ram_128k,
	plus_has_fdc,
	plus_has_tape,
	plus_mem_wait,
	plus_aspage_on,
	plus_asic_dout,
	plus_asic_rd,
	plus_vec_byte,
	plus_vec_valid,
	joy1,
	joy2,
	right_shift_mod,
	keypad_mod,
	ps2_key,
	ps2_mouse,
	joy1_sel,
	joy2_sel,
	key_nmi,
	key_reset,
	Fn,
	ppi_jumpers,
	crtc_type,
	sync_filter,
	no_wait,
	sna_load,
	sna_cpu_dir,
	sna_crtc_addr,
	sna_crtc_regs,
	sna_ga_inksel,
	sna_ga_palette,
	sna_ga_config,
	sna_ram_config,
	sna_rom_select,
	sna_ppi_a,
	sna_ppi_b,
	sna_ppi_c,
	sna_ppi_control,
	sna_psg_addr,
	sna_psg_regs,
	sna_hold,
	save_hold,
	sna_hsync,
	sna_dma_loop_cnt0,
	sna_dma_loop_cnt1,
	sna_dma_loop_cnt2,
	sna_dma_loop_addr0,
	sna_dma_loop_addr1,
	sna_dma_loop_addr2,
	sna_dma_pause_cnt0,
	sna_dma_pause_cnt1,
	sna_dma_pause_cnt2,
	sna_dma_pause_presc0,
	sna_dma_pause_presc1,
	sna_dma_pause_presc2,
	sna_crtc_hcc,
	sna_crtc_line,
	sna_crtc_raster,
	sna_crtc_vta,
	sna_crtc_hsw,
	sna_crtc_vsw,
	sna_crtc_vs,
	sna_crtc_adj,
	sna_ga_vsdelay,
	sna_ga_intcnt,
	sna_int_pending,
	sna_plus_chunk,
	plus_sna_wr,
	plus_sna_addr,
	plus_sna_data,
	plus_asic_reset,
	tape_in,
	tape_out,
	tape_motor,
	audio_l,
	audio_r,
	mode,
	red,
	green,
	blue,
	ssm_m1_fetch,
	ssm_bus_data,
	ssm_sync_observation,
	hblank,
	vblank,
	hsync,
	vsync,
	field,
	frame_field,
	raw_crt,
	pixel_vblank,
	vram_din,
	vram_addr,
	rom_map,
	ram64k,
	mem_addr,
	mem_rd,
	mem_wr,
	romen,
	phi_n,
	phi_en_n,
	phi_en_p,
	cpu_addr,
	cpu_dout,
	cpu_din,
	iorq,
	asic_iorq,
	mreq,
	rd,
	wr,
	m1,
	io_bus_byte,
	ga_ready,
	irq,
	nmi,
	cursor,
	snap_ga_inksel,
	snap_ga_border,
	snap_ga_inkr,
	snap_ga_hromen,
	snap_ga_lromen,
	snap_ga_mode,
	snap_ga_intcnt,
	snap_ga_hcnt,
	snap_ga_int_n,
	snap_crtc_addr,
	snap_crtc_regs,
	snap_crtc_hcc,
	snap_crtc_row,
	snap_crtc_line,
	snap_crtc_c5,
	snap_crtc_in_adj,
	snap_crtc_hsc,
	snap_crtc_hsync,
	snap_crtc_vsync_r,
	snap_crtc_vsw_elapsed,
	snap_mmu_rammap,
	snap_mmu_rampage,
	snap_mmu_rom_select_shadow,
	snap_ppi_porta_in,
	snap_ppi_portb_in,
	snap_ppi_opc_r,
	snap_ppi_mode,
	snap_psg_addr,
	snap_psg_regs,
	snap_printer_data,
	cpu_reg,
	cpu_insn_start,
	cpu_halt_n
);
	input reset;
	input clk;
	input ce_16;
	input plus_mode;
	input plus_unlocked;
	input plus_ram_128k;
	input plus_has_fdc;
	input plus_has_tape;
	input plus_mem_wait;
	input plus_aspage_on;
	output wire [7:0] plus_asic_dout;
	output wire plus_asic_rd;
	output wire [7:0] plus_vec_byte;
	output wire plus_vec_valid;
	input [6:0] joy1;
	input [6:0] joy2;
	input right_shift_mod;
	input keypad_mod;
	input [10:0] ps2_key;
	input [24:0] ps2_mouse;
	output wire joy1_sel;
	output wire joy2_sel;
	output wire key_nmi;
	output wire key_reset;
	output wire [9:0] Fn;
	input [3:0] ppi_jumpers;
	input crtc_type;
	input [1:0] sync_filter;
	input no_wait;
	input sna_load;
	input [211:0] sna_cpu_dir;
	input [4:0] sna_crtc_addr;
	input [143:0] sna_crtc_regs;
	input [4:0] sna_ga_inksel;
	input [135:0] sna_ga_palette;
	input [7:0] sna_ga_config;
	input [7:0] sna_ram_config;
	input [7:0] sna_rom_select;
	input [7:0] sna_ppi_a;
	input [7:0] sna_ppi_b;
	input [7:0] sna_ppi_c;
	input [7:0] sna_ppi_control;
	input [3:0] sna_psg_addr;
	input [127:0] sna_psg_regs;
	input sna_hold;
	input save_hold;
	input sna_hsync;
	input [11:0] sna_dma_loop_cnt0;
	input [11:0] sna_dma_loop_cnt1;
	input [11:0] sna_dma_loop_cnt2;
	input [15:0] sna_dma_loop_addr0;
	input [15:0] sna_dma_loop_addr1;
	input [15:0] sna_dma_loop_addr2;
	input [11:0] sna_dma_pause_cnt0;
	input [11:0] sna_dma_pause_cnt1;
	input [11:0] sna_dma_pause_cnt2;
	input [7:0] sna_dma_pause_presc0;
	input [7:0] sna_dma_pause_presc1;
	input [7:0] sna_dma_pause_presc2;
	input [7:0] sna_crtc_hcc;
	input [6:0] sna_crtc_line;
	input [4:0] sna_crtc_raster;
	input [4:0] sna_crtc_vta;
	input [3:0] sna_crtc_hsw;
	input [3:0] sna_crtc_vsw;
	input sna_crtc_vs;
	input sna_crtc_adj;
	input [1:0] sna_ga_vsdelay;
	input [5:0] sna_ga_intcnt;
	input sna_int_pending;
	input sna_plus_chunk;
	input plus_sna_wr;
	input [13:0] plus_sna_addr;
	input [7:0] plus_sna_data;
	input plus_asic_reset;
	input tape_in;
	output wire tape_out;
	output wire tape_motor;
	output wire [7:0] audio_l;
	output wire [7:0] audio_r;
	output wire [1:0] mode;
	output wire [3:0] red;
	output wire [3:0] green;
	output wire [3:0] blue;
	output wire ssm_m1_fetch;
	output wire [7:0] ssm_bus_data;
	output wire [20:0] ssm_sync_observation;
	output wire hblank;
	output wire vblank;
	output wire hsync;
	output wire vsync;
	output wire field;
	output wire frame_field;
	output wire raw_crt;
	output reg pixel_vblank;
	input [15:0] vram_din;
	output reg [14:0] vram_addr;
	input [255:0] rom_map;
	input ram64k;
	output wire [22:0] mem_addr;
	output wire mem_rd;
	output wire mem_wr;
	output wire romen;
	output wire phi_n;
	output wire phi_en_n;
	output wire phi_en_p;
	output wire [15:0] cpu_addr;
	output wire [7:0] cpu_dout;
	input [7:0] cpu_din;
	output wire iorq;
	output wire asic_iorq;
	output wire mreq;
	output wire rd;
	output wire wr;
	output wire m1;
	output reg [7:0] io_bus_byte;
	output wire ga_ready;
	input irq;
	input nmi;
	output wire cursor;
	output wire [4:0] snap_ga_inksel;
	output wire [4:0] snap_ga_border;
	output wire [79:0] snap_ga_inkr;
	output wire snap_ga_hromen;
	output wire snap_ga_lromen;
	output wire [1:0] snap_ga_mode;
	output wire [5:0] snap_ga_intcnt;
	output wire [4:0] snap_ga_hcnt;
	output wire snap_ga_int_n;
	output wire [4:0] snap_crtc_addr;
	output wire [127:0] snap_crtc_regs;
	output wire [7:0] snap_crtc_hcc;
	output wire [6:0] snap_crtc_row;
	output wire [4:0] snap_crtc_line;
	output wire [4:0] snap_crtc_c5;
	output wire snap_crtc_in_adj;
	output wire [3:0] snap_crtc_hsc;
	output wire snap_crtc_hsync;
	output wire snap_crtc_vsync_r;
	output wire [3:0] snap_crtc_vsw_elapsed;
	output wire [2:0] snap_mmu_rammap;
	output wire [4:0] snap_mmu_rampage;
	output wire [7:0] snap_mmu_rom_select_shadow;
	output wire [7:0] snap_ppi_porta_in;
	output wire [7:0] snap_ppi_portb_in;
	output wire [7:0] snap_ppi_opc_r;
	output wire [7:0] snap_ppi_mode;
	output wire [7:0] snap_psg_addr;
	output wire [127:0] snap_psg_regs;
	output wire [7:0] snap_printer_data;
	output wire [211:0] cpu_reg;
	output wire cpu_insn_start;
	output wire cpu_halt_n;
	wire crtc_shift;
	wire crtc_extra_byte;
	wire crtc_start_gen;
	wire crtc_end_gen;
	wire [1:0] sync_filter_req = (sync_filter == 2'd3 ? 2'd0 : sync_filter);
	reg [1:0] sync_filter_applied;
	wire sync_filter_commit;
	assign raw_crt = sync_filter_applied == 2'd2;
	wire [15:0] A;
	wire IORQ_n;
	wire plus_ready;
	wire board_iorq_n = IORQ_n | (plus_mode & ((~plus_ready & ~A[13]) | reset));
	wire RD_n;
	wire io_rd = ~(RD_n | board_iorq_n);
	wire WR_n;
	wire io_wr = ~(WR_n | board_iorq_n);
	wire MREQ_n;
	assign mem_rd = ~(RD_n | MREQ_n);
	assign mem_wr = ~(WR_n | MREQ_n);
	wire [7:0] D;
	assign cpu_dout = D;
	assign cpu_addr = A;
	wire M1_n;
	assign m1 = ~M1_n;
	assign iorq = ~IORQ_n;
	assign asic_iorq = ~board_iorq_n;
	assign mreq = ~MREQ_n;
	assign rd = ~RD_n;
	assign wr = ~WR_n;
	wire romen_n;
	assign romen = ~romen_n;
	wire ga_ready_o;
	wire ready = (plus_mode ? plus_ready : ga_ready_o);
	assign ga_ready = ready;
	wire RFSH_n;
	wire ga_int_n;
	wire plus_dma_int_req;
	wire plus_ga_int_n;
	wire plus_int_n = plus_ga_int_n & ~plus_dma_int_req;
	wire INT_n = (plus_mode ? plus_int_n : ga_int_n);
	wire [7:0] ppi_dout;
	wire [7:0] ppi_cpu_dout;
	wire plus_ga_open_read = (((((plus_mode & io_rd) & M1_n) & ~A[15]) & A[14]) & A[11]) & A[10];
	reg [7:0] memory_bus_byte;
	wire [7:0] cpu_read_data = (plus_ga_open_read ? memory_bus_byte : cpu_din);
	wire [7:0] crtc_dout;
	wire [7:0] plus_crtc_dout;
	wire [7:0] crtc_dout_sel = (plus_mode ? plus_crtc_dout : crtc_dout);
	wire [7:0] cpu_data_bus = (crtc_dout_sel & ppi_cpu_dout) & cpu_read_data;
	wire [7:0] plus_io_data = (io_rd ? io_bus_byte : D);
	wire m1_fetch = (~M1_n & ~MREQ_n) & ~RD_n;
	always @(posedge clk)
		if (reset)
			io_bus_byte <= 8'hff;
		else if (m1_fetch)
			io_bus_byte <= cpu_data_bus;
	assign ssm_m1_fetch = m1_fetch;
	assign ssm_bus_data = cpu_data_bus;
	wire printer_wr = io_wr & ~A[12];
	reg [7:0] printer_data;
	reg old_printer_wr;
	always @(posedge clk)
		if (reset) begin
			printer_data <= 8'd0;
			old_printer_wr <= 1'b0;
		end
		else begin
			old_printer_wr <= printer_wr;
			if (~old_printer_wr & printer_wr)
				printer_data <= D;
		end
	assign snap_printer_data = printer_data;
	wire cpu_ppi_access = (plus_mode & ~A[11]) & (io_rd | io_wr);
	reg cpu_ppi_started;
	wire dma_load_owner;
	wire dma_ppi_wait = (dma_load_owner & cpu_ppi_access) & ~cpu_ppi_started;
	T80pa CPU(
		.reset_n(~reset),
		.clk(clk),
		.cen_p((phi_en_p & ~sna_hold) & ~save_hold),
		.cen_n((phi_en_n & ~sna_hold) & ~save_hold),
		.a(A),
		.dout(D),
		.di(cpu_data_bus),
		.rd_n(RD_n),
		.wr_n(WR_n),
		.iorq_n(IORQ_n),
		.mreq_n(MREQ_n),
		.m1_n(M1_n),
		.rfsh_n(RFSH_n),
		.halt_n(cpu_halt_n),
		.busrq_n(1),
		.int_n(INT_n & ~irq),
		.nmi_n(~nmi),
		.wait_n((((ready | (IORQ_n & MREQ_n)) | no_wait) & ~plus_mem_wait) & ~dma_ppi_wait),
		.REG(cpu_reg),
		.INSN_START(cpu_insn_start),
		.DIRSet(sna_load),
		.DIR(sna_cpu_dir)
	);
	wire crtc_hs;
	wire crtc_vs;
	wire crtc_de;
	wire crtc_field;
	wire [13:0] MA;
	wire [4:0] RA;
	wire crtc_hsync_restart;
	wire crtc_frame_field;
	wire cclk_en_n;
	wire cclk_en_p;
	CRTC crtc(
		.CLOCK(clk),
		.CLKEN(cclk_en_n),
		.nCLKEN(cclk_en_p),
		.nRESET(~reset),
		.CRTC_TYPE(crtc_type),
		.ENABLE(io_rd | io_wr),
		.nCS(A[14]),
		.R_nW(A[9]),
		.RS(A[8]),
		.DI((~RD_n ? 8'hff : D)),
		.DO(crtc_dout),
		.SNA_LOAD(sna_load),
		.SNA_ADDR(sna_crtc_addr),
		.SNA_REGS(sna_crtc_regs),
		.VSYNC(crtc_vs),
		.HSYNC(crtc_hs),
		.HSYNC_RESTART(crtc_hsync_restart),
		.DE(crtc_de),
		.FIELD(crtc_field),
		.FRAME_FIELD(crtc_frame_field),
		.CURSOR(cursor),
		.MA(MA),
		.RA(RA),
		.SNAP_ADDR(snap_crtc_addr),
		.SNAP_REGS(snap_crtc_regs),
		.SNAP_HCC(snap_crtc_hcc),
		.SNAP_ROW(snap_crtc_row),
		.SNAP_LINE(snap_crtc_line),
		.SNAP_C5(snap_crtc_c5),
		.SNAP_IN_ADJ(snap_crtc_in_adj),
		.SNAP_HSC(snap_crtc_hsc),
		.SNAP_HSYNC(snap_crtc_hsync),
		.SNAP_VSYNC_R(snap_crtc_vsync_r),
		.SNAP_VSW_ELAPSED(snap_crtc_vsw_elapsed)
	);
	wire plus_crtc_hs;
	wire plus_crtc_vs;
	wire plus_crtc_de;
	wire [13:0] plus_ma;
	wire [4:0] plus_ra;
	wire [6:0] plus_vc;
	wire [4:0] plus_rc;
	wire plus_adj;
	wire plus_ras_n;
	wire plus_cas_n;
	wire plus_cpu_n;
	wire plus_cclk_en_p;
	wire plus_cclk_en_n;
	wire plus_phi_en_p;
	wire plus_phi_en_n;
	wire plus_phi_n;
	wire plus_hsync_o;
	wire plus_vsync_o;
	wire plus_vblank;
	wire [4:0] asic_border;
	wire [79:0] asic_inkr;
	wire leg_pal_wr;
	wire [4:0] leg_pal_addr;
	wire [4:0] leg_pal_data;
	wire [1:0] plus_gamode;
	wire [3:0] plus_rgb_r;
	wire [3:0] plus_rgb_g;
	wire [3:0] plus_rgb_b;
	reg [15:0] plus_vidword;
	wire plus_hwrap;
	wire plus_spr_en;
	wire [11:0] plus_spr_rgb;
	wire plus_spr_fq_req;
	wire [10:0] plus_spr_fq_addr;
	wire [7:0] plus_spr_fq_data;
	wire plus_spr_fq_ack;
	wire plus_spr_acc_en;
	wire [3:0] plus_spr_acc_idx;
	wire [159:0] plus_spr_x;
	wire [143:0] plus_spr_y;
	wire [63:0] plus_spr_mag;
	wire [179:0] plus_spr_pal;
	wire [4:0] plus_pal_raddr;
	wire [11:0] plus_pal_rdata;
	wire [13:0] ma_sel = (plus_mode ? plus_ma : MA);
	wire [4:0] ra_sel = (plus_mode ? plus_ra : RA);
	wire hs_sel = (plus_mode ? plus_crtc_hs : crtc_hs);
	wire vs_sel = (plus_mode ? plus_crtc_vs : crtc_vs);
	wire de_sel = (plus_mode ? plus_crtc_de : crtc_de);
	wire plus_field;
	assign field = (plus_mode ? plus_field : crtc_field);
	assign frame_field = (plus_mode ? plus_field : crtc_frame_field);
	wire plus_mode_update_en;
	wire asic_int_last_raster;
	wire [7:0] asic_pri;
	wire sna_ga_int_pending = sna_int_pending & ~plus_dma_int_req;
	asic_ga_timing asic_ga(
		.clk(clk),
		.cen_16(ce_16),
		.fast(no_wait),
		.RESET_N(~reset),
		.A(A[15:14]),
		.D(plus_io_data),
		.MREQ_N(MREQ_n),
		.M1_N(M1_n),
		.RD_N(RD_n),
		.IORQ_N(board_iorq_n),
		.HSYNC_I(plus_crtc_hs),
		.VSYNC_I(plus_crtc_vs),
		.pri(asic_pri),
		.crtc_line({plus_vc[5:0], plus_rc[2:0]}),
		.crtc_adj(plus_adj),
		.intack((plus_mode & ~M1_n) & asic_iorq),
		.int_last_raster(asic_int_last_raster),
		.CCLK(),
		.CCLK_EN_P(plus_cclk_en_p),
		.CCLK_EN_N(plus_cclk_en_n),
		.PHI_N(plus_phi_n),
		.PHI_EN_N(plus_phi_en_n),
		.PHI_EN_P(plus_phi_en_p),
		.RAS_N(plus_ras_n),
		.CASAD_N(),
		.CAS_N(plus_cas_n),
		.READY(plus_ready),
		.CPU_N(plus_cpu_n),
		.MWE_N(),
		.E244_N(),
		.plus_unlocked(plus_unlocked),
		.ROMEN_N(),
		.RAMRD_N(),
		.ROM(),
		.HSYNC_O(plus_hsync_o),
		.VSYNC_O(plus_vsync_o),
		.SYNC_N(),
		.INT_N(plus_ga_int_n),
		.VBLANK(plus_vblank),
		.MODE_SYNC_EN(),
		.ASIC_MODE_SYNC_EN(plus_mode_update_en),
		.MODE(),
		.BORDER_O(asic_border),
		.INKR_O(asic_inkr),
		.GAMODE_O(plus_gamode),
		.LEGACY_PAL_WR(leg_pal_wr),
		.LEGACY_PAL_ADDR(leg_pal_addr),
		.LEGACY_PAL_DATA(leg_pal_data),
		.SNA_LOAD(sna_load),
		.SNA_INKSEL(sna_ga_inksel),
		.SNA_PALETTE(sna_ga_palette),
		.SNA_CONFIG(sna_ga_config),
		.SNA_VSDELAY(sna_ga_vsdelay),
		.SNA_INTCNT(sna_ga_intcnt),
		.SNA_INT(sna_ga_int_pending),
		.SNA_VS(sna_crtc_vs),
		.SNA_HS(sna_hsync)
	);
	wire [7:0] asic_splt;
	wire [7:0] asic_ssa_hi;
	wire [7:0] asic_ssa_lo;
	wire [7:0] asic_sscr;
	asic_video asic_vid(
		.CLOCK(clk),
		.CLKEN(plus_cclk_en_n),
		.nRESET(~reset),
		.ENABLE(io_rd | io_wr),
		.nCS(A[14]),
		.R_nW(A[9]),
		.RS(A[8]),
		.DI(plus_io_data),
		.DO(plus_crtc_dout),
		.HSYNC(plus_crtc_hs),
		.VSYNC(plus_crtc_vs),
		.DE(plus_crtc_de),
		.FIELD(plus_field),
		.MA(plus_ma),
		.RA(plus_ra),
		.HCC(),
		.LINE(plus_vc),
		.ROW(plus_rc),
		.ADJ(plus_adj),
		.SPLT(asic_splt),
		.SSA({asic_ssa_hi[5:0], asic_ssa_lo[7:0]}),
		.SSCR(asic_sscr),
		.PIXEN(ce_16),
		.VIDEOD(plus_vidword),
		.GAMODE(plus_gamode),
		.MODE_UPDATE_EN(plus_mode_update_en),
		.BORDER_I(asic_border),
		.INKR_I(asic_inkr),
		.RGB_R(plus_rgb_r),
		.RGB_G(plus_rgb_g),
		.RGB_B(plus_rgb_b),
		.PEN(),
		.HWRAP(plus_hwrap),
		.SPR_EN(plus_spr_en),
		.SPR_RGB(plus_spr_rgb),
		.PAL_EN(1'b1),
		.PAL_ADDR(plus_pal_raddr),
		.PAL_RGB(plus_pal_rdata),
		.SNA_LOAD(sna_load),
		.SNA_ADDR(sna_crtc_addr),
		.SNA_REGS(sna_crtc_regs),
		.SNA_HCC(sna_crtc_hcc),
		.SNA_LINE(sna_crtc_line),
		.SNA_RASTER(sna_crtc_raster),
		.SNA_VTA(sna_crtc_vta),
		.SNA_HSW(sna_crtc_hsw),
		.SNA_VSW(sna_crtc_vsw),
		.SNA_VS(sna_crtc_vs),
		.SNA_HS(sna_hsync),
		.SNA_ADJ(sna_crtc_adj),
		.SNA_MODE(sna_ga_config[1:0])
	);
	wire [7:0] asic_regs_dout;
	wire asic_regs_rd;
	wire asic_page_active = plus_mode & plus_aspage_on;
	wire [7:0] dma_sar0_lo;
	wire [7:0] dma_sar0_hi;
	wire [7:0] dma_ppr0;
	wire dma_sar0_wr;
	wire dma_ppr0_wr;
	wire [7:0] dma_sar1_lo;
	wire [7:0] dma_sar1_hi;
	wire [7:0] dma_ppr1;
	wire dma_sar1_wr;
	wire dma_ppr1_wr;
	wire [7:0] dma_sar2_lo;
	wire [7:0] dma_sar2_hi;
	wire [7:0] dma_ppr2;
	wire dma_sar2_wr;
	wire dma_ppr2_wr;
	wire [2:0] dma_dcsr_ena;
	wire [2:0] dma_dcsr_ena_clr;
	wire [2:0] dma_int_set;
	wire [15:0] dma_ram_addr;
	wire dma_ram_req;
	wire psg_dma_bdir;
	wire psg_dma_bc1;
	wire [7:0] psg_dma_dout;
	wire psg_dma_active;
	wire asic_read_driven;
	always @(posedge clk)
		if (reset)
			memory_bus_byte <= 8'hff;
		else if (mem_rd && !(plus_asic_rd && !asic_read_driven))
			memory_bus_byte <= cpu_data_bus;
	wire [11:0] plus_spr_wr_addr;
	wire [3:0] plus_spr_wr_data;
	wire plus_spr_wr_en;
	asic_regs asic_page(
		.clk(clk),
		.reset(plus_asic_reset),
		.asic_cs(asic_page_active & (A[15:14] == 2'b01)),
		.mem_wr(mem_wr),
		.mem_rd(mem_rd),
		.A(A[13:0]),
		.D_in(D),
		.D_out(asic_regs_dout),
		.read_driven(asic_read_driven),
		.leg_pal_wr(leg_pal_wr),
		.leg_pal_addr(leg_pal_addr),
		.leg_pal_data(leg_pal_data),
		.leg_border(asic_border),
		.leg_inkr(asic_inkr),
		.pal_raddr(plus_pal_raddr),
		.pal_rdata(plus_pal_rdata),
		.pri(asic_pri),
		.splt(asic_splt),
		.sscr(asic_sscr),
		.ivr(),
		.ssa_hi(asic_ssa_hi),
		.ssa_lo(asic_ssa_lo),
		.dcsr(),
		.intack_raster(asic_int_last_raster),
		.intack_m1(plus_mode & ~M1_n),
		.intack((plus_mode & ~M1_n) & asic_iorq),
		.int_pending(~plus_ga_int_n),
		.dma_int_set(dma_int_set),
		.vec_byte(plus_vec_byte),
		.vec_valid(plus_vec_valid),
		.sprq_req(plus_spr_fq_req),
		.sprq_addr(plus_spr_fq_addr),
		.sprq_data(plus_spr_fq_data),
		.sprq_ack(plus_spr_fq_ack),
		.spr_acc_en(plus_spr_acc_en),
		.spr_acc_idx(plus_spr_acc_idx),
		.spr_wr_en(plus_spr_wr_en),
		.spr_wr_addr(plus_spr_wr_addr),
		.spr_wr_data(plus_spr_wr_data),
		.spr_x_view(plus_spr_x),
		.spr_y_view(plus_spr_y),
		.spr_mag_view(plus_spr_mag),
		.spr_pal_view(plus_spr_pal),
		.sar0_lo(dma_sar0_lo),
		.sar0_hi(dma_sar0_hi),
		.ppr0(dma_ppr0),
		.sar0_wr(dma_sar0_wr),
		.sar1_lo(dma_sar1_lo),
		.sar1_hi(dma_sar1_hi),
		.ppr1(dma_ppr1),
		.sar1_wr(dma_sar1_wr),
		.sar2_lo(dma_sar2_lo),
		.sar2_hi(dma_sar2_hi),
		.ppr2(dma_ppr2),
		.sar2_wr(dma_sar2_wr),
		.ppr0_wr(dma_ppr0_wr),
		.ppr1_wr(dma_ppr1_wr),
		.ppr2_wr(dma_ppr2_wr),
		.dcsr_ena_out(dma_dcsr_ena),
		.dcsr_ena_clr(dma_dcsr_ena_clr),
		.dma_int_req(plus_dma_int_req),
		.sna_wr(plus_sna_wr),
		.sna_addr(plus_sna_addr),
		.sna_data(plus_sna_data),
		.sna_pal_load(sna_load),
		.sna_pal_plain(~sna_plus_chunk),
		.sna_pal_hdr(sna_ga_palette)
	);
	assign plus_asic_dout = (plus_asic_rd && !asic_read_driven ? memory_bus_byte : asic_regs_dout);
	assign plus_asic_rd = (asic_page_active & (A[15:14] == 2'b01)) & mem_rd;
	wire cpu_ppi_write = cpu_ppi_access & io_wr;
	reg cpu_ppi_stolen;
	reg [7:0] cpu_ppi_read_latch;
	always @(posedge clk)
		if (reset) begin
			cpu_ppi_started <= 1'b0;
			cpu_ppi_stolen <= 1'b0;
			cpu_ppi_read_latch <= 8'hff;
		end
		else begin
			if (~cpu_ppi_access) begin
				cpu_ppi_started <= 1'b0;
				cpu_ppi_stolen <= 1'b0;
			end
			else begin
				if (~dma_load_owner)
					cpu_ppi_started <= 1'b1;
				if (cpu_ppi_started & dma_load_owner)
					cpu_ppi_stolen <= 1'b1;
			end
			if (((cpu_ppi_access & io_rd) & ~dma_load_owner) & ~cpu_ppi_started)
				cpu_ppi_read_latch <= ppi_dout;
		end
	assign ppi_cpu_dout = (((plus_mode & cpu_ppi_started) & io_rd) & (cpu_ppi_stolen | dma_load_owner) ? cpu_ppi_read_latch : ppi_dout);
	wire cpu_bsr_pc7 = ((cpu_ppi_write & (A[9:8] == 2'b11)) & ~D[7]) & (D[3:1] == 3'd7);
	wire cpu_bsr_pc6 = ((cpu_ppi_write & (A[9:8] == 2'b11)) & ~D[7]) & (D[3:1] == 3'd6);
	wire [7:0] portC;
	wire [1:0] cpu_pc76_after = (A[9:8] == 2'b10 ? D[7:6] : {(cpu_bsr_pc7 ? D[0] : portC[7]), (cpu_bsr_pc6 ? D[0] : portC[6])});
	wire cpu_psg_write = (cpu_ppi_write & (cpu_pc76_after == 2'b10)) & ((((A[9:8] == 2'b00) | (A[9:8] == 2'b10)) | cpu_bsr_pc7) | cpu_bsr_pc6);
	reg [7:0] cpu_psg_addr;
	asic_dma dma_sound(
		.clk(clk),
		.reset(reset || !plus_mode),
		.cclk_en_p(plus_cclk_en_p),
		.cclk_en_n(plus_cclk_en_n),
		.hsync(plus_crtc_hs),
		.sna_load(sna_load),
		.sna_loop_cnt0(sna_dma_loop_cnt0),
		.sna_loop_cnt1(sna_dma_loop_cnt1),
		.sna_loop_cnt2(sna_dma_loop_cnt2),
		.sna_loop_addr0(sna_dma_loop_addr0),
		.sna_loop_addr1(sna_dma_loop_addr1),
		.sna_loop_addr2(sna_dma_loop_addr2),
		.sna_pause_cnt0(sna_dma_pause_cnt0),
		.sna_pause_cnt1(sna_dma_pause_cnt1),
		.sna_pause_cnt2(sna_dma_pause_cnt2),
		.sna_pause_presc0(sna_dma_pause_presc0),
		.sna_pause_presc1(sna_dma_pause_presc1),
		.sna_pause_presc2(sna_dma_pause_presc2),
		.sna_hsync(sna_hsync),
		.sar0_lo(dma_sar0_lo),
		.sar0_hi(dma_sar0_hi),
		.ppr0(dma_ppr0),
		.sar0_wr(dma_sar0_wr),
		.ppr0_wr(dma_ppr0_wr),
		.sar1_lo(dma_sar1_lo),
		.sar1_hi(dma_sar1_hi),
		.ppr1(dma_ppr1),
		.sar1_wr(dma_sar1_wr),
		.ppr1_wr(dma_ppr1_wr),
		.sar2_lo(dma_sar2_lo),
		.sar2_hi(dma_sar2_hi),
		.ppr2(dma_ppr2),
		.sar2_wr(dma_sar2_wr),
		.ppr2_wr(dma_ppr2_wr),
		.dcsr_ena(dma_dcsr_ena),
		.dcsr_ena_clr(dma_dcsr_ena_clr),
		.dma_int_set(dma_int_set),
		.sar0_addr(),
		.sar1_addr(),
		.sar2_addr(),
		.ram_req(dma_ram_req),
		.ram_addr(dma_ram_addr),
		.ram_data(vram_din),
		.cpu_psg_addr(cpu_psg_addr),
		.cpu_ppi_access(cpu_ppi_access),
		.cpu_psg_write(cpu_psg_write),
		.dma_load_owner(dma_load_owner),
		.dma_load_busy(),
		.psg_bdir(psg_dma_bdir),
		.psg_bc1(psg_dma_bc1),
		.psg_dout(psg_dma_dout),
		.psg_active(psg_dma_active)
	);
	assign plus_spr_en = 1'b0;
	assign plus_spr_rgb = 12'd0;
	assign plus_spr_fq_req = 1'b0;
	assign plus_spr_fq_addr = 11'd0;
	reg [7:0] vram_d;
	always @(posedge clk)
		if (reset)
			plus_vidword <= 16'd0;
		else begin
			if (plus_cclk_en_p)
				plus_vidword[7:0] <= vram_d;
			if (plus_cclk_en_n)
				plus_vidword[15:8] <= vram_d;
		end
	wire [14:0] crtc_vram_addr = {ma_sel[13:12], ra_sel[2:0], ma_sel[9:0]};
	reg vram_bs;
	reg [7:0] vram_din_shift;
	wire ga_cas_n;
	wire cas_n = (plus_mode ? plus_cas_n : ga_cas_n);
	wire ga_cpu_n;
	wire cpu_n = (plus_mode ? plus_cpu_n : ga_cpu_n);
	wire ga_ras_n;
	wire ras_n = (plus_mode ? plus_ras_n : ga_ras_n);
	always @(posedge clk) begin : sv2v_autoblock_1
		reg cas_n_old;
		cas_n_old <= cas_n;
		if (!cpu_n)
			vram_bs <= 0;
		else begin
			if (plus_mode && dma_ram_req)
				vram_addr <= {dma_ram_addr[15:14], dma_ram_addr[13:1]};
			else
				vram_addr <= crtc_vram_addr;
			if ((!ras_n & !cas_n_old) & cas_n)
				vram_bs <= 1;
			if (!ras_n & !cas_n) begin
				if ((sync_filter_applied == 2'd0) & crtc_shift) begin
					if (vram_bs)
						vram_din_shift <= (de_sel ? vram_din[15:8] : 8'd0);
					vram_d <= (vram_bs ? vram_din[7:0] : vram_din_shift);
				end
				else
					vram_d <= (vram_bs ? vram_din[15:8] : vram_din[7:0]);
			end
		end
		if (reset | sync_filter_commit)
			vram_din_shift <= 8'd0;
	end
	wire ga_cclk_en_n;
	wire ga_cclk_en_p;
	assign cclk_en_p = (plus_mode ? plus_cclk_en_p : ga_cclk_en_p);
	assign cclk_en_n = (plus_mode ? plus_cclk_en_n : ga_cclk_en_n);
	wire e244_n;
	wire [7:0] ga_din = (e244_n ? vram_d : D);
	wire ga_hsync_o;
	wire hsync_filtered;
	wire ga_vsync_o;
	wire vsync_filtered;
	wire hblank_filtered;
	wire ga_vblank_o;
	wire vblank_filtered;
	wire hsync_ga = (plus_mode ? plus_hsync_o : ga_hsync_o);
	wire vsync_ga = (plus_mode ? plus_vsync_o : ga_vsync_o);
	wire vblank_ga = (plus_mode ? plus_vblank : ga_vblank_o);
	assign sync_filter_commit = ((sync_filter_applied != sync_filter_req) & vblank_filtered) & ~cpu_n;
	always @(posedge clk)
		if (reset)
			sync_filter_applied <= sync_filter_req;
		else if (sync_filter_commit)
			sync_filter_applied <= sync_filter_req;
	always @(posedge clk)
		if (reset)
			pixel_vblank <= 1'b0;
		else if (ce_16)
			pixel_vblank <= (sync_filter_applied != 2'd0) & vblank_ga;
	crt_filter_output_select crt_filter_output_select(
		.MODE(sync_filter_applied),
		.HSYNC_FILTERED(hsync_filtered),
		.VSYNC_FILTERED(vsync_filtered),
		.HBLANK_FILTERED(hblank_filtered),
		.VBLANK_FILTERED(vblank_filtered),
		.HSYNC_RAW(hsync_ga),
		.VSYNC_RAW(vsync_ga),
		.HBLANK_RAW(hs_sel),
		.VBLANK_RAW(vblank_ga),
		.HSYNC_OUT(hsync),
		.VSYNC_OUT(vsync),
		.HBLANK_OUT(hblank),
		.VBLANK_OUT(vblank)
	);
	wire [15:0] filter_sync_observation;
	assign ssm_sync_observation = {1'b0, filter_sync_observation, sync_filter_applied, sync_filter};
	crt_filter crt_filter(
		.CLK(clk),
		.CE_4(phi_en_n),
		.HSYNC_I(hs_sel),
		.VSYNC_I(vs_sel),
		.HSYNC_O(hsync_filtered),
		.VSYNC_O(vsync_filtered),
		.HBLANK(hblank_filtered),
		.HBLANK_LIVE(),
		.VBLANK(vblank_filtered),
		.SHIFT(crtc_shift),
		.EXTRA_BYTE(crtc_extra_byte),
		.START_GEN(crtc_start_gen),
		.END_GEN(crtc_end_gen),
		.SYNC_OBSERVATION(filter_sync_observation)
	);
	wire [1:0] ga_mode;
	wire [1:0] ga_red;
	wire [1:0] ga_green;
	wire [1:0] ga_blue;
	assign mode = (plus_mode ? plus_gamode : ga_mode);
	wire [11:0] selected_source_rgb = (plus_mode ? {plus_rgb_r, plus_rgb_g, plus_rgb_b} : {2'b00, ga_red, 2'b00, ga_green, 2'b00, ga_blue});
	reg [11:0] full_rgb_history [0:7];
	reg rgb_owner;
	reg rgb_sampled;
	reg rgb_old_hs;
	reg rgb_raw_open;
	reg rgb_raw_fell;
	reg rgb_start_owned;
	reg rgb_start_seen;
	reg rgb_end_seen;
	reg rgb_correction;
	initial begin
		rgb_owner = 0;
		rgb_sampled = 0;
		rgb_old_hs = 0;
		rgb_raw_open = 0;
		rgb_raw_fell = 0;
		rgb_start_owned = 0;
		rgb_start_seen = 0;
		rgb_end_seen = 0;
		rgb_correction = 0;
	end
	wire rgb_owner_match = rgb_owner == plus_mode;
	wire rgb_context_clear = (((reset | sna_load) | sync_filter_commit) | ~rgb_owner_match) | (sync_filter_applied != 2'd0);
	wire rgb_raw_rise = ~rgb_old_hs & hs_sel;
	wire rgb_raw_fall = rgb_old_hs & ~hs_sel;
	wire rgb_new_start = rgb_start_seen != crtc_start_gen;
	wire rgb_new_end = rgb_end_seen != crtc_end_gen;
	integer rgb_i;
	always @(posedge clk) begin
		rgb_owner <= plus_mode;
		if (rgb_context_clear) begin
			for (rgb_i = 0; rgb_i < 8; rgb_i = rgb_i + 1)
				full_rgb_history[rgb_i] <= 12'd0;
			rgb_sampled <= 0;
			rgb_old_hs <= hs_sel;
			rgb_raw_open <= 0;
			rgb_raw_fell <= 0;
			rgb_start_owned <= 0;
			rgb_start_seen <= crtc_start_gen;
			rgb_end_seen <= crtc_end_gen;
			rgb_correction <= 0;
		end
		else begin
			if (ce_16) begin
				full_rgb_history[0] <= selected_source_rgb;
				for (rgb_i = 1; rgb_i < 8; rgb_i = rgb_i + 1)
					full_rgb_history[rgb_i] <= full_rgb_history[rgb_i - 1];
			end
			rgb_old_hs <= hs_sel;
			rgb_start_seen <= crtc_start_gen;
			rgb_end_seen <= crtc_end_gen;
			if (!rgb_sampled) begin
				rgb_sampled <= 1;
				rgb_raw_open <= 0;
				rgb_raw_fell <= 0;
				rgb_start_owned <= 0;
				rgb_correction <= 0;
			end
			else begin
				if (rgb_raw_rise) begin
					rgb_raw_open <= 1;
					rgb_raw_fell <= 0;
					rgb_start_owned <= 0;
				end
				if (rgb_new_start)
					rgb_start_owned <= rgb_raw_open | rgb_raw_rise;
				if (rgb_raw_fall) begin
					rgb_raw_fell <= rgb_raw_open;
					rgb_raw_open <= 0;
				end
				if (rgb_new_end) begin
					rgb_correction <= ((~rgb_new_start & rgb_start_owned) & (rgb_raw_fell | (rgb_raw_fall & rgb_raw_open))) & crtc_extra_byte;
					rgb_start_owned <= 0;
					rgb_raw_fell <= 0;
				end
			end
		end
	end
	wire [11:0] rendered_rgb = (rgb_correction & rgb_owner_match ? full_rgb_history[7] : selected_source_rgb);
	assign red = rendered_rgb[11:8];
	assign green = rendered_rgb[7:4];
	assign blue = rendered_rgb[3:0];
	wire ga_phi_n;
	wire ga_phi_en_n;
	wire ga_phi_en_p;
	assign phi_n = (plus_mode ? plus_phi_n : ga_phi_n);
	assign phi_en_n = (plus_mode ? plus_phi_en_n : ga_phi_en_n);
	assign phi_en_p = (plus_mode ? plus_phi_en_p : ga_phi_en_p);
	ga40010 GateArray(
		.clk(clk),
		.cen_16(ce_16),
		.fast(no_wait),
		.RESET_N(~reset),
		.A(A[15:14]),
		.D(ga_din),
		.MREQ_N(MREQ_n),
		.M1_N(M1_n),
		.RD_N(RD_n),
		.IORQ_N(IORQ_n),
		.HSYNC_I(crtc_hs),
		.HSYNC_RESTART_I(crtc_hsync_restart & ~plus_mode),
		.VSYNC_I(crtc_vs),
		.DISPEN(crtc_de),
		.CCLK(),
		.CCLK_EN_P(ga_cclk_en_p),
		.CCLK_EN_N(ga_cclk_en_n),
		.PHI_N(ga_phi_n),
		.PHI_EN_N(ga_phi_en_n),
		.PHI_EN_P(ga_phi_en_p),
		.RAS_N(ga_ras_n),
		.CAS_N(ga_cas_n),
		.READY(ga_ready_o),
		.CASAD_N(),
		.CPU_N(ga_cpu_n),
		.MWE_N(),
		.E244_N(e244_n),
		.ROMEN_N(romen_n),
		.RAMRD_N(),
		.HSYNC_O(ga_hsync_o),
		.VSYNC_O(ga_vsync_o),
		.VBLANK(ga_vblank_o),
		.MODE(ga_mode),
		.SYNC_N(),
		.INT_N(ga_int_n),
		.BLUE_OE_N(ga_blue[0]),
		.BLUE(ga_blue[1]),
		.GREEN_OE_N(ga_green[0]),
		.GREEN(ga_green[1]),
		.RED_OE_N(ga_red[0]),
		.RED(ga_red[1]),
		.SNA_LOAD(sna_load),
		.SNA_INKSEL(sna_ga_inksel),
		.SNA_PALETTE(sna_ga_palette),
		.SNA_CONFIG(sna_ga_config),
		.SNAP_INKSEL(snap_ga_inksel),
		.SNAP_BORDER(snap_ga_border),
		.SNAP_INKR(snap_ga_inkr),
		.SNAP_HROMEN(snap_ga_hromen),
		.SNAP_LROMEN(snap_ga_lromen),
		.SNAP_MODE(snap_ga_mode),
		.SNAP_INTCNT(snap_ga_intcnt),
		.SNAP_HCNT(snap_ga_hcnt)
	);
	Amstrad_MMU MMU(
		.CLK(clk),
		.reset(reset),
		.ram64k(ram64k),
		.romen_n((plus_mode ? 1'b1 : romen_n)),
		.rom_map(rom_map),
		.A(A),
		.D(D),
		.io_WR(io_wr),
		.sna_load(sna_load),
		.sna_ram_config(sna_ram_config),
		.sna_rom_select(sna_rom_select),
		.ram_A(mem_addr),
		.snap_rammap(snap_mmu_rammap),
		.snap_rampage(snap_mmu_rampage),
		.snap_rom_select_shadow(snap_mmu_rom_select_shadow)
	);
	wire [7:0] portAout;
	wire [7:0] portAin;
	always @(posedge clk)
		if (reset)
			cpu_psg_addr <= 8'd0;
		else if (sna_load)
			cpu_psg_addr <= {4'h0, sna_psg_addr};
		else if ((~psg_dma_active && portC[7]) && portC[6])
			cpu_psg_addr <= portAout;
	wire [7:0] ppi_ipb = {(!plus_mode || plus_has_tape ? tape_in : 1'b1), 2'b11, ppi_jumpers, vs_sel};
	i8255 PPI(
		.reset(reset),
		.clk_sys(clk),
		.addr(A[9:8]),
		.idata(D),
		.odata(ppi_dout),
		.cs(~A[11]),
		.we(io_wr & ~dma_ppi_wait),
		.oe(io_rd & ~dma_ppi_wait),
		.ipa(portAin),
		.opa(portAout),
		.ipb(ppi_ipb),
		.opb(),
		.ipc(8'hff),
		.opc(portC),
		.plus_mode(plus_mode),
		.sna_load(sna_load),
		.sna_opa(sna_ppi_a),
		.sna_opb(sna_ppi_b),
		.sna_opc(sna_ppi_c),
		.sna_control(sna_ppi_control),
		.snap_opc_r(snap_ppi_opc_r),
		.snap_mode(snap_ppi_mode)
	);
	assign tape_motor = (!plus_mode || plus_has_tape ? portC[4] : 1'b0);
	assign tape_out = (!plus_mode || plus_has_tape ? portC[5] : 1'b0);
	wire [7:0] ch_a;
	wire [7:0] ch_b;
	assign audio_l = {1'b0, ch_a[7:1]} + {2'b00, ch_b[7:2]};
	wire [7:0] ch_c;
	assign audio_r = {1'b0, ch_c[7:1]} + {2'b00, ch_b[7:2]};
	wire psg_bc_mux = (plus_mode && psg_dma_active ? psg_dma_bc1 : portC[6]);
	wire psg_bdir_mux = (plus_mode && psg_dma_active ? psg_dma_bdir : portC[7]);
	wire [7:0] psg_di_mux = (plus_mode && psg_dma_active ? psg_dma_dout : portAout);
	wire [7:0] kbd_out;
	YM2149 PSG(
		.RESET(reset),
		.CLK(clk),
		.CE(cclk_en_p),
		.SEL(0),
		.MODE(0),
		.BC(psg_bc_mux),
		.BDIR(psg_bdir_mux),
		.DI(psg_di_mux),
		.DO(portAin),
		.CHANNEL_A(ch_a),
		.CHANNEL_B(ch_b),
		.CHANNEL_C(ch_c),
		.IOA_in(kbd_out),
		.IOB_in(8'hff),
		.SNA_LOAD(sna_load),
		.SNA_ADDR(sna_psg_addr),
		.SNA_REGS(sna_psg_regs),
		.SNAP_ADDR(snap_psg_addr),
		.SNAP_REGS(snap_psg_regs)
	);
	assign snap_ppi_porta_in = portAin;
	assign snap_ppi_portb_in = ppi_ipb;
	assign snap_ga_int_n = ga_int_n;
	hid HID(
		.reset(reset),
		.clk(clk),
		.right_shift_mod(right_shift_mod),
		.keypad_mod(keypad_mod),
		.ps2_key(ps2_key),
		.ps2_mouse(ps2_mouse),
		.joystick1(joy1),
		.joystick2(joy2),
		.Y(portC[3:0]),
		.X(kbd_out),
		.key_nmi(key_nmi),
		.key_reset(key_reset),
		.Fn(Fn)
	);
	assign joy1_sel = portC[3:0] == 9;
	assign joy2_sel = portC[3:0] == 6;
endmodule
