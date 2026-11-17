`default_nettype wire
module ga40010 (
	clk,
	cen_16,
	fast,
	RESET_N,
	A,
	D,
	MREQ_N,
	M1_N,
	RD_N,
	IORQ_N,
	HSYNC_I,
	HSYNC_RESTART_I,
	VSYNC_I,
	DISPEN,
	CCLK,
	CCLK_EN_P,
	CCLK_EN_N,
	PHI_N,
	PHI_EN_N,
	PHI_EN_P,
	RAS_N,
	CAS_N,
	READY,
	CASAD_N,
	CPU_N,
	MWE_N,
	E244_N,
	ROMEN_N,
	RAMRD_N,
	ROM,
	MODE,
	HSYNC_O,
	VSYNC_O,
	SYNC_N,
	INT_N,
	VBLANK,
	BLUE_OE_N,
	BLUE,
	GREEN_OE_N,
	GREEN,
	RED_OE_N,
	RED,
	SNA_LOAD,
	SNA_INKSEL,
	SNA_PALETTE,
	SNA_CONFIG,
	SNAP_INKSEL,
	SNAP_BORDER,
	SNAP_INKR,
	SNAP_HROMEN,
	SNAP_LROMEN,
	SNAP_MODE,
	SNAP_INTCNT,
	SNAP_HCNT
);
	input clk;
	input cen_16;
	input fast;
	input RESET_N;
	input [15:14] A;
	input [7:0] D;
	input MREQ_N;
	input M1_N;
	input RD_N;
	input IORQ_N;
	input HSYNC_I;
	input HSYNC_RESTART_I;
	input VSYNC_I;
	input DISPEN;
	output wire CCLK;
	output wire CCLK_EN_P;
	output wire CCLK_EN_N;
	output reg PHI_N;
	output reg PHI_EN_N;
	output reg PHI_EN_P;
	output reg RAS_N;
	output wire CAS_N;
	output wire READY;
	output reg CASAD_N;
	output wire CPU_N;
	output wire MWE_N;
	output wire E244_N;
	output wire ROMEN_N;
	output wire RAMRD_N;
	output wire ROM;
	output wire [1:0] MODE;
	output wire HSYNC_O;
	output wire VSYNC_O;
	output wire SYNC_N;
	output reg INT_N;
	output wire VBLANK;
	output wire BLUE_OE_N;
	output wire BLUE;
	output wire GREEN_OE_N;
	output wire GREEN;
	output wire RED_OE_N;
	output wire RED;
	input SNA_LOAD;
	input [4:0] SNA_INKSEL;
	input [135:0] SNA_PALETTE;
	input [7:0] SNA_CONFIG;
	output wire [4:0] SNAP_INKSEL;
	output wire [4:0] SNAP_BORDER;
	output wire [79:0] SNAP_INKR;
	output wire SNAP_HROMEN;
	output wire SNAP_LROMEN;
	output wire [1:0] SNAP_MODE;
	output wire [5:0] SNAP_INTCNT;
	output wire [4:0] SNAP_HCNT;
	wire reset = ~RESET_N;
	reg [7:0] S;
	wire U204 = (((reset & ~M1_N) & ~IORQ_N) & ~RD_N) | (S[6] & ~S[7]);
	always @(posedge clk)
		if (cen_16) begin
			S[0] <= ~S[7];
			S[1] <= S[0] | U204;
			S[2] <= S[1] | U204;
			S[3] <= S[2] | U204;
			S[4] <= S[3] | U204;
			S[5] <= S[4] | U204;
			S[6] <= S[5] | U204;
			S[7] <= S[6];
		end
	always @(posedge clk)
		if (cen_16) begin
			PHI_N <= (S[1] ^ S[3]) | (S[5] ^ S[7]);
			RAS_N <= (S[6] | ~S[2]) & S[0];
			CASAD_N <= RAS_N;
		end
	wire [1:1] sv2v_tmp_1C2DD;
	assign sv2v_tmp_1C2DD = cen_16 & ((((S == 8'hc0) || (S == 8'h03)) || (S == 8'h3f)) || (S == 8'hfc));
	always @(*) PHI_EN_N = sv2v_tmp_1C2DD;
	wire [1:1] sv2v_tmp_45A33;
	assign sv2v_tmp_45A33 = cen_16 & ((((S == 8'h00) || (S == 8'h0f)) || (S == 8'hff)) || (S == 8'hf0));
	always @(*) PHI_EN_P = sv2v_tmp_45A33;
	rslatch ready_l(
		.clock(clk),
		.s(S[3] & ~S[6]),
		.r(CASAD_N),
		.q(READY)
	);
	assign CPU_N = ~(S[1] & ~S[7]);
	assign CCLK = ~(S[2] | S[5]);
	assign CCLK_EN_P = cen_16 & (S == 8'he0);
	assign CCLK_EN_N = cen_16 & (S == 8'h03);
	assign MWE_N = ~((RD_N & S[0]) & S[5]);
	assign E244_N = ~((~IORQ_N & S[2]) & S[3]);
	casgen_sync casgen_sync(
		.clk(clk),
		.cen_16(cen_16),
		.RESET_N(RESET_N),
		.M1_N(M1_N),
		.PHI_N(PHI_N),
		.MREQ_N(MREQ_N),
		.S(S),
		.CAS_N(CAS_N)
	);
	wire HCNTLT28;
	wire mode_sync_en;
	wire irq_reset;
	wire [1:1] sv2v_tmp_syncgen_sync_INT_N;
	always @(*) INT_N = sv2v_tmp_syncgen_sync_INT_N;
	syncgen_sync syncgen_sync(
		.clk(clk),
		.CCLK_EN_N(CCLK_EN_N),
		.RESET_N(RESET_N),
		.MREQ_N(MREQ_N),
		.M1_N(M1_N),
		.IORQ_N(IORQ_N),
		.HSYNC_I(HSYNC_I),
		.HSYNC_RESTART_I(HSYNC_RESTART_I),
		.VSYNC_I(VSYNC_I),
		.irq_reset(irq_reset),
		.HSYNC_O(HSYNC_O),
		.VSYNC_O(VSYNC_O),
		.SYNC_N(SYNC_N),
		.INT_N(sv2v_tmp_syncgen_sync_INT_N),
		.HCNTLT28(HCNTLT28),
		.mode_sync_en(mode_sync_en),
		.SNAP_INTCNT(SNAP_INTCNT),
		.SNAP_HCNT(SNAP_HCNT)
	);
	assign VBLANK = HCNTLT28;
	reg [4:0] inksel;
	reg [4:0] border;
	reg [79:0] inkr;
	reg hromen;
	reg lromen;
	reg mode1;
	reg mode0;
	wire reg_latch = (S[0] & S[7]) | (fast & ~E244_N);
	wire reg_sel = (((reg_latch & ~IORQ_N) & ~A[15]) & A[14]) & M1_N;
	wire ink_en = (reg_sel & ~D[7]) & ~D[6];
	wire border_en = ((reg_sel & ~D[7]) & D[6]) & inksel[4];
	wire ctrl_en = (reg_sel & D[7]) & ~D[6];
	wire inkr_en = ((reg_sel & ~D[7]) & D[6]) & ~inksel[4];
	assign irq_reset = ctrl_en & D[4];
	always @(posedge clk)
		if (SNA_LOAD) begin : sv2v_autoblock_1
			integer i;
			inksel <= SNA_INKSEL;
			for (i = 0; i < 16; i = i + 1)
				inkr[(15 - i) * 5+:5] <= SNA_PALETTE[i * 8+:5];
			border <= SNA_PALETTE[128+:5];
			{hromen, lromen, mode1, mode0} <= SNA_CONFIG[3:0];
		end
		else begin
			if (ink_en)
				inksel <= D[4:0];
			if (reset)
				border <= 5'b10000;
			else if (border_en)
				border <= D[4:0];
			if (reset)
				{hromen, lromen, mode1, mode0} <= 0;
			else if (ctrl_en)
				{hromen, lromen, mode1, mode0} <= D[3:0];
			if (inkr_en)
				inkr[(15 - inksel[3:0]) * 5+:5] <= D[4:0];
		end
	assign MODE = {mode1, mode0};
	assign SNAP_INKSEL = inksel;
	assign SNAP_BORDER = border;
	genvar _gv_gi_1;
	generate
		for (_gv_gi_1 = 0; _gv_gi_1 < 16; _gv_gi_1 = _gv_gi_1 + 1) begin : gen_snap_inkr
			localparam gi = _gv_gi_1;
			assign SNAP_INKR[gi * 5+:5] = inkr[(15 - gi) * 5+:5];
		end
	endgenerate
	assign SNAP_HROMEN = hromen;
	assign SNAP_LROMEN = lromen;
	assign SNAP_MODE = {mode1, mode0};
	wire rom = ((~lromen & ~A[15]) & ~A[14]) | ((~hromen & A[15]) & A[14]);
	assign ROM = rom;
	assign ROMEN_N = (~rom | MREQ_N) | RD_N;
	assign RAMRD_N = (rom | MREQ_N) | RD_N;
	wire vidbuf_clk_en = cen_16 & ((S == 8'he0) || (S == 8'h03));
	reg DISPEN_BUF;
	reg [7:0] VIDEO_BUF;
	reg VIDEO_BUF_VALID = 1'b0;
	always @(posedge clk)
		if (reset | SNA_LOAD)
			VIDEO_BUF_VALID <= 1'b0;
		else if (vidbuf_clk_en)
			VIDEO_BUF_VALID <= 1'b1;
	always @(posedge clk)
		if (vidbuf_clk_en) begin
			DISPEN_BUF <= DISPEN;
			VIDEO_BUF <= D;
		end
	video video_sync(
		.MODEL_RESET(reset | SNA_LOAD),
		.PHASE_P(PHI_EN_P),
		.PHASE_N(PHI_EN_N),
		.MODEL_MODE((SNA_LOAD ? SNA_CONFIG[1:0] : 2'b00)),
		.clk(clk),
		.cen_16(cen_16),
		.S(S),
		.DISPEN_BUF(DISPEN_BUF),
		.PHI_N(PHI_N),
		.MODE({mode1, mode0}),
		.MODE_SYNC(clk),
		.MODE_SYNC_EN(mode_sync_en),
		.VIDEO(VIDEO_BUF),
		.VIDEO_VALID(VIDEO_BUF_VALID),
		.BORDER(border),
		.INKR(inkr),
		.FORCE_BLANK(HCNTLT28 | HSYNC_I),
		.BLUE_OE_N(BLUE_OE_N),
		.BLUE(BLUE),
		.GREEN_OE_N(GREEN_OE_N),
		.GREEN(GREEN),
		.RED_OE_N(RED_OE_N),
		.RED(RED)
	);
endmodule
