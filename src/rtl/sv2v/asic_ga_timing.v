`default_nettype wire
module asic_ga_timing (
	clk,
	cen_16,
	fast,
	RESET_N,
	plus_unlocked,
	A,
	D,
	MREQ_N,
	M1_N,
	RD_N,
	IORQ_N,
	HSYNC_I,
	VSYNC_I,
	CCLK,
	CCLK_EN_P,
	CCLK_EN_N,
	PHI_N,
	PHI_EN_N,
	PHI_EN_P,
	RAS_N,
	CAS_N,
	CASAD_N,
	READY,
	CPU_N,
	MWE_N,
	E244_N,
	ROMEN_N,
	RAMRD_N,
	ROM,
	pri,
	crtc_line,
	crtc_adj,
	intack,
	int_last_raster,
	HSYNC_O,
	VSYNC_O,
	SYNC_N,
	INT_N,
	VBLANK,
	MODE_SYNC_EN,
	ASIC_MODE_SYNC_EN,
	MODE,
	BORDER_O,
	INKR_O,
	GAMODE_O,
	LEGACY_PAL_WR,
	LEGACY_PAL_ADDR,
	LEGACY_PAL_DATA,
	SNA_LOAD,
	SNA_INKSEL,
	SNA_PALETTE,
	SNA_CONFIG,
	SNA_VSDELAY,
	SNA_INTCNT,
	SNA_INT,
	SNA_VS,
	SNA_HS
);
	input clk;
	input cen_16;
	input fast;
	input RESET_N;
	input plus_unlocked;
	input [15:14] A;
	input [7:0] D;
	input MREQ_N;
	input M1_N;
	input RD_N;
	input IORQ_N;
	input HSYNC_I;
	input VSYNC_I;
	output wire CCLK;
	output wire CCLK_EN_P;
	output wire CCLK_EN_N;
	output reg PHI_N;
	output wire PHI_EN_N;
	output wire PHI_EN_P;
	output reg RAS_N;
	output wire CAS_N;
	output reg CASAD_N;
	output wire READY;
	output wire CPU_N;
	output wire MWE_N;
	output wire E244_N;
	output wire ROMEN_N;
	output wire RAMRD_N;
	output wire ROM;
	input [7:0] pri;
	input [8:0] crtc_line;
	input crtc_adj;
	input intack;
	output wire int_last_raster;
	output wire HSYNC_O;
	output wire VSYNC_O;
	output wire SYNC_N;
	output wire INT_N;
	output wire VBLANK;
	output wire MODE_SYNC_EN;
	output reg ASIC_MODE_SYNC_EN;
	output wire [1:0] MODE;
	output wire [4:0] BORDER_O;
	output wire [79:0] INKR_O;
	output wire [1:0] GAMODE_O;
	output wire LEGACY_PAL_WR;
	output wire [4:0] LEGACY_PAL_ADDR;
	output wire [4:0] LEGACY_PAL_DATA;
	input SNA_LOAD;
	input [4:0] SNA_INKSEL;
	input [135:0] SNA_PALETTE;
	input [7:0] SNA_CONFIG;
	input [1:0] SNA_VSDELAY;
	input [5:0] SNA_INTCNT;
	input SNA_INT;
	input SNA_VS;
	input SNA_HS;
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
	assign PHI_EN_N = cen_16 & ((((S == 8'hc0) || (S == 8'h03)) || (S == 8'h3f)) || (S == 8'hfc));
	assign PHI_EN_P = cen_16 & ((((S == 8'h00) || (S == 8'h0f)) || (S == 8'hff)) || (S == 8'hf0));
	assign CCLK = ~(S[2] | S[5]);
	assign CCLK_EN_P = cen_16 & (S == 8'he0);
	assign CCLK_EN_N = cen_16 & (S == 8'h03);
	assign CPU_N = ~(S[1] & ~S[7]);
	assign MWE_N = ~((RD_N & S[0]) & S[5]);
	assign E244_N = ~((~IORQ_N & S[2]) & S[3]);
	wire ready_set = S[3] & ~S[6];
	wire ready_rst = CASAD_N;
	reg ready_hold;
	reg ready_q;
	always @(*)
		if (ready_set)
			ready_q = 1'b1;
		else if (ready_rst)
			ready_q = 1'b0;
		else
			ready_q = ready_hold;
	always @(posedge clk) ready_hold <= ready_q;
	assign READY = ready_q;
	reg U708;
	reg M1_N_d;
	reg MREQ_N_d;
	always @(posedge clk) begin
		M1_N_d <= M1_N;
		MREQ_N_d <= MREQ_N;
	end
	always @(posedge clk or negedge RESET_N)
		if (!RESET_N)
			U708 <= 1'b1;
		else if (~M1_N_d & M1_N)
			U708 <= 1'b0;
		else if (~MREQ_N_d & MREQ_N)
			U708 <= 1'b1;
	reg S_d1;
	reg S_d2;
	always @(posedge clk)
		if (cen_16) begin
			S_d1 <= ((~S[4] & S[5]) | (~S[3] & S[1])) | (S[1] & S[7]);
			S_d2 <= S_d1;
		end
	wire U710 = ((~U708 | MREQ_N) | ~S[4]) | S[5];
	wire u712_s = S_d1;
	wire u712_r = ~(S[2] & U710);
	reg u712_hold;
	reg u712_q;
	always @(*)
		if (u712_r)
			u712_q = 1'b0;
		else if (u712_s)
			u712_q = 1'b1;
		else
			u712_q = u712_hold;
	always @(posedge clk) u712_hold <= u712_q;
	assign CAS_N = (u712_q | S_d1) | S_d2;
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
	wire ctrl_en = ((reg_sel & D[7]) & ~D[6]) & (~plus_unlocked | ~D[5]);
	wire inkr_en = ((reg_sel & ~D[7]) & D[6]) & ~inksel[4];
	wire irq_reset = ctrl_en & D[4];
	integer sna_i;
	always @(posedge clk) begin
		if (reset)
			border <= 5'b10000;
		else if (SNA_LOAD)
			border <= SNA_PALETTE[128+:5];
		else if (border_en)
			border <= D[4:0];
		if (reset)
			{hromen, lromen, mode1, mode0} <= 4'd0;
		else if (SNA_LOAD)
			{hromen, lromen, mode1, mode0} <= SNA_CONFIG[3:0];
		else if (ctrl_en)
			{hromen, lromen, mode1, mode0} <= D[3:0];
		if (reset) begin
			inksel <= 5'd0;
			inkr <= 80'd0;
		end
		if (!reset && SNA_LOAD) begin
			inksel <= SNA_INKSEL;
			for (sna_i = 0; sna_i < 16; sna_i = sna_i + 1)
				inkr[sna_i * 5+:5] <= SNA_PALETTE[sna_i * 8+:5];
		end
		if ((!reset && !SNA_LOAD) && ink_en)
			inksel <= D[4:0];
		if ((!reset && !SNA_LOAD) && inkr_en)
			inkr[inksel[3:0] * 5+:5] <= D[4:0];
	end
	assign BORDER_O = border;
	assign INKR_O = inkr;
	assign GAMODE_O = {mode1, mode0};
	assign MODE = {mode1, mode0};
	assign LEGACY_PAL_WR = ~reset & (inkr_en | border_en);
	assign LEGACY_PAL_ADDR = (border_en ? 5'd16 : {1'b0, inksel[3:0]});
	assign LEGACY_PAL_DATA = D[4:0];
	wire rom_map_rom = ((~lromen & ~A[15]) & ~A[14]) | ((~hromen & A[15]) & A[14]);
	assign ROM = rom_map_rom;
	assign ROMEN_N = (~rom_map_rom | MREQ_N) | RD_N;
	assign RAMRD_N = (rom_map_rom | MREQ_N) | RD_N;
	reg [5:0] intcnt_reg;
	reg [5:0] intcnt_next;
	reg [4:0] hcnt_reg;
	reg [4:0] hcnt_next;
	reg [3:0] hdelay_reg;
	reg vsync_d;
	wire hsync_n = ~HSYNC_I;
	reg hsync_n_d;
	reg vsync_o_d;
	reg irqack_rst;
	wire [4:0] sna_hcnt_seed = (SNA_VSDELAY == 2'd2 ? 5'h00 : (SNA_VSDELAY == 2'd1 ? 5'h01 : (SNA_VS ? 5'h06 : 5'h1e)));
	wire [4:0] sna_hcnt_next_seed = (SNA_VSDELAY == 2'd2 ? 5'h01 : (SNA_VSDELAY == 2'd1 ? 5'h06 : (SNA_VS ? 5'h07 : 5'h1e)));
	wire sna_vsync_o_seed = (SNA_VSDELAY == 2'd0) & SNA_VS;
	reg [4:0] hcnt_comb;
	wire VSYNC_O_int = (hcnt_comb[2] & ~hcnt_comb[3]) & ~hcnt_comb[4];
	always @(posedge clk)
		if (SNA_LOAD) begin
			hsync_n_d <= ~SNA_HS;
			vsync_d <= SNA_VS;
			vsync_o_d <= sna_vsync_o_seed;
		end
		else begin
			hsync_n_d <= hsync_n;
			if (CCLK_EN_N) begin
				vsync_d <= VSYNC_I;
				vsync_o_d <= VSYNC_O_int;
			end
		end
	wire hcnt_cnt = ~hsync_n_d & hsync_n;
	wire [4:0] hcnt_comb_base = (hcnt_cnt ? hcnt_next : hcnt_reg);
	wire hcnt_res0 = ~RESET_N | (((hcnt_cnt & hcnt_next[2]) & hcnt_next[3]) & hcnt_next[4]);
	wire hcnt_res1 = VSYNC_I & ~vsync_d;
	always @(*) begin
		hcnt_comb = hcnt_comb_base;
		if (hcnt_res0)
			hcnt_comb[0] = 1'b0;
		if (hcnt_res1)
			hcnt_comb[4:1] = 4'd0;
	end
	wire VBLANK_comb = ~((hcnt_comb[2] & hcnt_comb[3]) & hcnt_comb[4]);
	always @(posedge clk)
		if (SNA_LOAD) begin
			hcnt_reg <= sna_hcnt_seed;
			hcnt_next <= sna_hcnt_next_seed;
		end
		else begin
			hcnt_reg <= hcnt_comb;
			case (hcnt_comb)
				5'h00: hcnt_next <= 5'h01;
				5'h01: hcnt_next <= 5'h06;
				5'h06: hcnt_next <= 5'h07;
				5'h07: hcnt_next <= 5'h04;
				5'h04: hcnt_next <= 5'h05;
				5'h05: hcnt_next <= 5'h0a;
				5'h0a: hcnt_next <= 5'h0b;
				5'h0b: hcnt_next <= 5'h08;
				5'h08: hcnt_next <= 5'h09;
				5'h09: hcnt_next <= 5'h0e;
				5'h0e: hcnt_next <= 5'h0f;
				5'h0f: hcnt_next <= 5'h0c;
				5'h0c: hcnt_next <= 5'h0d;
				5'h0d: hcnt_next <= 5'h12;
				5'h12: hcnt_next <= 5'h13;
				5'h13: hcnt_next <= 5'h10;
				5'h10: hcnt_next <= 5'h11;
				5'h11: hcnt_next <= 5'h16;
				5'h16: hcnt_next <= 5'h17;
				5'h17: hcnt_next <= 5'h14;
				5'h14: hcnt_next <= 5'h15;
				5'h15: hcnt_next <= 5'h1a;
				5'h1a: hcnt_next <= 5'h1b;
				5'h1b: hcnt_next <= 5'h18;
				5'h18: hcnt_next <= 5'h19;
				5'h19: hcnt_next <= 5'h1e;
				default:
					;
			endcase
		end
	wire hdelay_res0 = hsync_n | hdelay_reg[3];
	wire hdelay_res1 = hsync_n;
	reg hdelay_res0_d;
	reg hdelay2d;
	reg [3:0] hdelay_comb;
	always @(posedge clk)
		if (SNA_LOAD) begin
			hdelay_res0_d <= ~SNA_HS;
			hdelay2d <= 1'b0;
		end
		else begin
			hdelay_res0_d <= hdelay_res0;
			hdelay2d <= hdelay_comb[2];
		end
	reg mode_sync_en_w;
	always @(*) begin
		hdelay_comb = hdelay_reg;
		mode_sync_en_w = (~hdelay_res0_d & hdelay_res0) & hdelay2d;
		if (hdelay_res0)
			hdelay_comb[2:0] = 3'd0;
		if (hdelay_res1)
			hdelay_comb[3] = 1'b0;
	end
	assign MODE_SYNC_EN = mode_sync_en_w;
	always @(posedge clk)
		if (SNA_LOAD)
			hdelay_reg <= 4'd0;
		else if (hdelay_res0 | hdelay_res1)
			hdelay_reg <= hdelay_comb;
		else if (CCLK_EN_N)
			case (hdelay_comb)
				4'h0: hdelay_reg <= 4'h1;
				4'h1: hdelay_reg <= 4'h6;
				4'h6: hdelay_reg <= 4'h7;
				4'h7: hdelay_reg <= 4'h4;
				4'h4: hdelay_reg <= 4'h5;
				4'h5: hdelay_reg <= 4'h8;
				default:
					;
			endcase
	assign HSYNC_O = hdelay_comb[2];
	assign SYNC_N = ~(VSYNC_O_int ^ HSYNC_O);
	reg mode_hsync_d;
	reg mode_tracking;
	reg mode_fell;
	reg [2:0] mode_elapsed;
	always @(posedge clk) begin
		ASIC_MODE_SYNC_EN <= 1'b0;
		if (reset | SNA_LOAD) begin
			mode_hsync_d <= (~reset & SNA_LOAD) & SNA_HS;
			mode_tracking <= 1'b0;
			mode_fell <= 1'b0;
			mode_elapsed <= 3'd0;
		end
		else begin
			mode_hsync_d <= HSYNC_I;
			if (HSYNC_I & ~mode_hsync_d) begin
				mode_tracking <= 1'b1;
				mode_fell <= 1'b0;
				mode_elapsed <= 3'd0;
			end
			else if (mode_tracking) begin
				if (~HSYNC_I & mode_hsync_d) begin
					if (mode_elapsed < 3'd2)
						mode_tracking <= 1'b0;
					else
						mode_fell <= 1'b1;
				end
				if (CCLK_EN_N) begin
					if (mode_fell | (mode_elapsed == 3'd6)) begin
						ASIC_MODE_SYNC_EN <= 1'b1;
						mode_tracking <= 1'b0;
						mode_fell <= 1'b0;
					end
					else
						mode_elapsed <= mode_elapsed + 3'd1;
				end
			end
		end
	end
	reg intcnt_hs_q;
	reg pri_hs_d;
	reg pri_valid;
	always @(posedge clk)
		if (!pri_valid)
			intcnt_hs_q <= HSYNC_I;
		else
			intcnt_hs_q <= pri_hs_d;
	wire intcnt_cnt = (pri_valid & intcnt_hs_q) & ~pri_hs_d;
	wire intcnt52 = ((intcnt_cnt & intcnt_next[2]) & intcnt_next[4]) & intcnt_next[5];
	wire intcntclr_52_s = intcnt52;
	wire intcntclr_52_r = pri_hs_d;
	reg intcntclr_52_hold;
	reg intcntclr_52;
	always @(*)
		if (intcntclr_52_r)
			intcntclr_52 = 1'b0;
		else if (intcntclr_52_s)
			intcntclr_52 = 1'b1;
		else
			intcntclr_52 = intcntclr_52_hold;
	always @(posedge clk) intcntclr_52_hold <= (SNA_LOAD ? 1'b0 : intcntclr_52);
	wire intcntclr_4 = VSYNC_O_int & ~vsync_o_d;
	reg vs_rephase_pending;
	always @(posedge clk)
		if (reset || SNA_LOAD)
			vs_rephase_pending <= 1'b0;
		else if (intcntclr_4 && pri_valid)
			vs_rephase_pending <= 1'b1;
		else if (intcnt_cnt)
			vs_rephase_pending <= 1'b0;
	wire intcnt_res0 = ((intcntclr_52 | intcntclr_4) | vs_rephase_pending) | irq_reset;
	reg pri_adj_d;
	reg [8:0] pri_line_d;
	wire pri_c = (pri_hs_d && (pri != 8'd0)) && ((({1'b0, pri} == pri_line_d) && !pri_adj_d) || (({1'b0, pri} == crtc_line) && !crtc_adj));
	reg pri_c_q;
	wire raster_fire = (((!reset && !SNA_LOAD) && pri_valid) && pri_c) && !pri_c_q;
	wire intcnt_res1 = (intcnt_res0 | irqack_rst) | raster_fire;
	reg [5:0] intcnt_comb;
	always @(*) begin
		intcnt_comb = intcnt_reg;
		if (intcnt_res0)
			intcnt_comb[4:0] = 5'd0;
		else if (intcnt_cnt)
			intcnt_comb = intcnt_next;
		if (intcnt_res1)
			intcnt_comb[5] = 1'b0;
	end
	always @(posedge clk)
		if (SNA_LOAD) begin
			intcnt_reg <= SNA_INTCNT;
			intcnt_next <= SNA_INTCNT + 6'd1;
		end
		else begin
			intcnt_reg <= intcnt_comb;
			intcnt_next <= intcnt_comb + 6'd1;
		end
	wire classic_raw_n;
	reg ack_raster;
	reg intack_d;
	wire ack_raster_selected = (intack_d ? ack_raster : !INT_N);
	wire irqack_s = ~((classic_raw_n | IORQ_N) | M1_N) & ack_raster_selected;
	wire irqack_r = M1_N;
	reg irqack_hold;
	always @(*)
		if (irqack_s)
			irqack_rst = 1'b1;
		else if (irqack_r)
			irqack_rst = 1'b0;
		else
			irqack_rst = irqack_hold;
	always @(posedge clk) irqack_hold <= (SNA_LOAD ? 1'b0 : irqack_rst);
	always @(posedge clk) begin
		if (CCLK_EN_N) begin
			pri_hs_d <= HSYNC_I;
			pri_line_d <= crtc_line;
			pri_adj_d <= crtc_adj;
		end
		if (reset || SNA_LOAD)
			pri_valid <= 1'b0;
		else if (CCLK_EN_N)
			pri_valid <= 1'b1;
	end
	always @(posedge clk) pri_c_q <= (pri_valid ? pri_c : 1'b1);
	wire int_reset = irq_reset | irqack_rst;
	wire int_ack_active = int_reset | intack;
	wire classic_ack_active = int_reset | (intack & ack_raster_selected);
	reg cnt5;
	wire classic_fire = (pri == 8'd0) && (~intcnt_comb[5] & cnt5);
	reg classic_int_n;
	reg programmed_int_n;
	reg classic_delivery_n;
	wire normal_wrap_prompt = ((classic_fire & intcnt_cnt) & intcnt52) & ~intcntclr_4;
	assign classic_raw_n = programmed_int_n & (classic_int_n | (pri != 8'd0));
	assign INT_N = programmed_int_n & ((classic_int_n | classic_delivery_n) | (pri != 8'd0));
	reg raster_fire_pending;
	reg raster_ack_seen;
	reg last_raster;
	always @(posedge clk) begin
		intack_d <= intack;
		if (reset || SNA_LOAD)
			ack_raster <= 1'b0;
		else if (intack && !intack_d)
			ack_raster <= !INT_N;
		if ((reset || SNA_LOAD) || M1_N)
			raster_ack_seen <= 1'b0;
		else if (intack && !intack_d)
			raster_ack_seen <= 1'b1;
		if (reset)
			last_raster <= 1'b0;
		else if (SNA_LOAD)
			last_raster <= 1'b0;
		else if ((intack && !intack_d) && !raster_ack_seen)
			last_raster <= !INT_N;
	end
	assign int_last_raster = last_raster;
	always @(posedge clk)
		if (SNA_LOAD) begin
			cnt5 <= SNA_INTCNT[5];
			classic_int_n <= ~(SNA_INT && (pri == 8'd0));
			programmed_int_n <= ~(SNA_INT && (pri != 8'd0));
			classic_delivery_n <= ~(SNA_INT && (pri == 8'd0));
			raster_fire_pending <= 1'b0;
		end
		else begin
			cnt5 <= intcnt_comb[5];
			if (reset)
				raster_fire_pending <= 1'b0;
			else if (int_ack_active) begin
				if (raster_fire)
					raster_fire_pending <= 1'b1;
			end
			else
				raster_fire_pending <= 1'b0;
			if (int_ack_active) begin
				if (classic_ack_active)
					classic_int_n <= 1'b1;
				else if (classic_fire)
					classic_int_n <= 1'b0;
				programmed_int_n <= 1'b1;
			end
			else if (raster_fire_pending | raster_fire)
				programmed_int_n <= 1'b0;
			else if (classic_fire)
				classic_int_n <= 1'b0;
			if (classic_ack_active)
				classic_delivery_n <= 1'b1;
			else if (normal_wrap_prompt)
				classic_delivery_n <= 1'b0;
			else if (CCLK_EN_N)
				classic_delivery_n <= classic_int_n;
		end
	assign VSYNC_O = VSYNC_O_int;
	assign VBLANK = VBLANK_comb;
endmodule
