`default_nettype wire
module asic_video (
	CLOCK,
	CLKEN,
	nRESET,
	ENABLE,
	nCS,
	R_nW,
	RS,
	DI,
	DO,
	HSYNC,
	VSYNC,
	DE,
	FIELD,
	MA,
	RA,
	HCC,
	LINE,
	ROW,
	ADJ,
	SPLT,
	SSA,
	SSCR,
	PIXEN,
	VIDEOD,
	MODE_UPDATE_EN,
	GAMODE,
	BORDER_I,
	INKR_I,
	RGB_R,
	RGB_G,
	RGB_B,
	PEN,
	HWRAP,
	SPR_EN,
	SPR_RGB,
	PAL_EN,
	PAL_ADDR,
	PAL_RGB,
	SNA_LOAD,
	SNA_ADDR,
	SNA_REGS,
	SNA_HCC,
	SNA_LINE,
	SNA_RASTER,
	SNA_VTA,
	SNA_HSW,
	SNA_VSW,
	SNA_VS,
	SNA_HS,
	SNA_ADJ,
	SNA_MODE
);
	input CLOCK;
	input CLKEN;
	input nRESET;
	input ENABLE;
	input nCS;
	input R_nW;
	input RS;
	input [7:0] DI;
	output reg [7:0] DO;
	output reg HSYNC;
	output reg VSYNC;
	output wire DE;
	output wire FIELD;
	output wire [13:0] MA;
	output wire [4:0] RA;
	output wire [7:0] HCC;
	output wire [6:0] LINE;
	output wire [4:0] ROW;
	output wire ADJ;
	input [7:0] SPLT;
	input [13:0] SSA;
	input [7:0] SSCR;
	input PIXEN;
	input [15:0] VIDEOD;
	input MODE_UPDATE_EN;
	input [1:0] GAMODE;
	input [4:0] BORDER_I;
	input [79:0] INKR_I;
	output reg [3:0] RGB_R;
	output reg [3:0] RGB_G;
	output reg [3:0] RGB_B;
	output reg [4:0] PEN;
	output wire HWRAP;
	input SPR_EN;
	input [11:0] SPR_RGB;
	input PAL_EN;
	output wire [4:0] PAL_ADDR;
	input [11:0] PAL_RGB;
	input SNA_LOAD;
	input [4:0] SNA_ADDR;
	input [143:0] SNA_REGS;
	input [7:0] SNA_HCC;
	input [6:0] SNA_LINE;
	input [4:0] SNA_RASTER;
	input [4:0] SNA_VTA;
	input [3:0] SNA_HSW;
	input [3:0] SNA_VSW;
	input SNA_VS;
	input SNA_HS;
	input SNA_ADJ;
	input [1:0] SNA_MODE;
	reg [4:0] addr;
	reg [7:0] R0_h_total;
	reg [7:0] R1_h_displayed;
	reg [7:0] R2_h_sync_pos;
	reg [3:0] R3_h_sync_width;
	reg [3:0] R3_v_sync_width;
	reg [6:0] R6_v_displayed;
	reg [6:0] R7_v_sync_pos;
	reg [1:0] R8_skew;
	reg [1:0] R8_interlace;
	reg [6:0] R4_v_total;
	reg [4:0] R5_v_total_adj;
	reg [4:0] R9_v_max_line;
	reg [7:0] R12_start_addr_h;
	reg [7:0] R13_start_addr_l;
	reg [5:0] R14_cursor_h;
	reg [7:0] R15_cursor_l;
	reg [5:0] R16_pen_h;
	reg [7:0] R17_pen_l;
	always @(posedge CLOCK)
		if (!nRESET) begin
			addr <= 5'd0;
			R0_h_total <= 8'd0;
			R1_h_displayed <= 8'd0;
			R2_h_sync_pos <= 8'd0;
			{R3_v_sync_width, R3_h_sync_width} <= 8'd0;
			R4_v_total <= 7'd0;
			R5_v_total_adj <= 5'd0;
			R6_v_displayed <= 7'd0;
			R7_v_sync_pos <= 7'd0;
			{R8_skew, R8_interlace} <= 4'd0;
			R9_v_max_line <= 5'd0;
			R12_start_addr_h <= 8'd0;
			R13_start_addr_l <= 8'd0;
			R14_cursor_h <= 6'd0;
			R15_cursor_l <= 8'd0;
			R16_pen_h <= 6'd0;
			R17_pen_l <= 8'd0;
		end
		else if (SNA_LOAD) begin
			addr <= SNA_ADDR;
			R0_h_total <= SNA_REGS[0+:8];
			R1_h_displayed <= SNA_REGS[8+:8];
			R2_h_sync_pos <= SNA_REGS[16+:8];
			{R3_v_sync_width, R3_h_sync_width} <= SNA_REGS[24+:8];
			R4_v_total <= SNA_REGS[32+:7];
			R5_v_total_adj <= SNA_REGS[40+:5];
			R6_v_displayed <= SNA_REGS[48+:7];
			R7_v_sync_pos <= SNA_REGS[56+:7];
			{R8_skew, R8_interlace} <= {SNA_REGS[69:68], SNA_REGS[65:64]};
			R9_v_max_line <= SNA_REGS[72+:5];
			R12_start_addr_h <= SNA_REGS[96+:8];
			R13_start_addr_l <= SNA_REGS[104+:8];
			R14_cursor_h <= SNA_REGS[112+:6];
			R15_cursor_l <= SNA_REGS[120+:8];
			R16_pen_h <= SNA_REGS[128+:6];
			R17_pen_l <= SNA_REGS[136+:8];
		end
		else if ((ENABLE & ~nCS) & ~R_nW) begin
			if (~RS)
				addr <= DI[4:0];
			else
				case (addr)
					5'd0: R0_h_total <= DI;
					5'd1: R1_h_displayed <= DI;
					5'd2: R2_h_sync_pos <= DI;
					5'd3: {R3_v_sync_width, R3_h_sync_width} <= DI;
					5'd4: R4_v_total <= DI[6:0];
					5'd5: R5_v_total_adj <= DI[4:0];
					5'd6: R6_v_displayed <= DI[6:0];
					5'd7: R7_v_sync_pos <= DI[6:0];
					5'd8: {R8_skew, R8_interlace} <= {DI[5:4], DI[1:0]};
					5'd9: R9_v_max_line <= DI[4:0];
					5'd12: R12_start_addr_h <= DI;
					5'd13: R13_start_addr_l <= DI;
					5'd14: R14_cursor_h <= DI[5:0];
					5'd15: R15_cursor_l <= DI;
					default:
						;
				endcase
		end
	reg [7:0] hcc;
	reg entered_terminal_match;
	wire hcc_equal = hcc == R0_h_total;
	wire hcc_last = hcc_equal | entered_terminal_match;
	wire [7:0] hcc_next = (hcc_last ? 8'h00 : hcc + 8'd1);
	always @(posedge CLOCK)
		if (!nRESET)
			entered_terminal_match <= 1'b1;
		else if (SNA_LOAD)
			entered_terminal_match <= SNA_HCC == SNA_REGS[0+:8];
		else if (CLKEN)
			entered_terminal_match <= hcc_next == R0_h_total;
	always @(posedge CLOCK)
		if (!nRESET)
			hcc <= 8'h00;
		else if (SNA_LOAD)
			hcc <= SNA_HCC;
		else if (CLKEN)
			hcc <= hcc_next;
	reg [6:0] charline;
	reg [4:0] raster;
	reg in_adj;
	reg interlace_line;
	reg parity_frame;
	reg parity_c9;
	wire ivm_active = R8_interlace == 2'b11;
	wire sync_interlace_active = R8_interlace == 2'b01;
	wire c9_done = (in_adj ? 1'b0 : raster >= R9_v_max_line);
	reg entered_r4_match;
	wire r4_write_active = (((ENABLE & ~nCS) & ~R_nW) & RS) & (addr == 5'd4);
	wire last_charline = (charline == R4_v_total) | ((hcc_last & entered_r4_match) & r4_write_active);
	wire enter_adj = ((~interlace_line & c9_done) & last_charline) & (R5_v_total_adj != 5'd0);
	wire adj_end_n = (raster + 5'd1) >= R5_v_total_adj;
	wire body_frame_end = (c9_done & last_charline) & (R5_v_total_adj == 5'd0);
	wire extra_line_due = (ivm_active | sync_interlace_active) & ~parity_frame;
	wire enter_interlace_line = extra_line_due & (body_frame_end | (in_adj & adj_end_n));
	wire frame_wrap = body_frame_end & ~extra_line_due;
	wire adj_frame_wrap = (in_adj & adj_end_n) & ~extra_line_due;
	wire interlace_frame_wrap = interlace_line;
	wire frame_restart = (frame_wrap | adj_frame_wrap) | interlace_frame_wrap;
	wire row_parity_n = (R9_v_max_line[0] ? ~parity_c9 : parity_c9);
	wire frame_parity_n = ~parity_frame;
	wire [4:0] ivm_step = (raster + 5'd2) | {4'b0000, parity_c9};
	wire [4:0] ivm_row_reload = (frame_wrap ? {4'b0000, frame_parity_n} : (enter_adj ? 5'd0 : {4'b0000, row_parity_n}));
	wire [4:0] raster_n = (interlace_line ? (ivm_active ? {4'b0000, frame_parity_n} : 5'd0) : (in_adj ? (adj_end_n ? (enter_interlace_line ? 5'd0 : (ivm_active ? {4'b0000, frame_parity_n} : 5'd0)) : raster + 5'd1) : (c9_done ? (enter_interlace_line ? 5'd0 : (ivm_active ? ivm_row_reload : 5'd0)) : (ivm_active ? ivm_step : raster + 5'd1))));
	wire [6:0] charline_n = (interlace_line ? 7'd0 : (in_adj & adj_end_n ? (enter_interlace_line ? charline : 7'd0) : (in_adj ? charline : (enter_adj ? charline : (frame_wrap ? 7'd0 : (c9_done ? (enter_interlace_line ? charline : charline + 7'd1) : charline))))));
	wire adj_n = (in_adj ? !adj_end_n : enter_adj);
	wire interlace_line_n = (interlace_line ? 1'b0 : enter_interlace_line);
	always @(posedge CLOCK)
		if (!nRESET || SNA_LOAD)
			entered_r4_match <= 1'b0;
		else if (CLKEN)
			entered_r4_match <= (hcc_last ? charline_n : charline) == R4_v_total;
	always @(posedge CLOCK)
		if (!nRESET) begin
			charline <= 7'd0;
			raster <= 5'd0;
			in_adj <= 1'b0;
			interlace_line <= 1'b0;
			parity_frame <= 1'b0;
			parity_c9 <= 1'b0;
		end
		else if (SNA_LOAD) begin
			charline <= SNA_LINE;
			raster <= (SNA_ADJ ? SNA_VTA : SNA_RASTER);
			in_adj <= SNA_ADJ;
			interlace_line <= 1'b0;
			parity_frame <= 1'b0;
			parity_c9 <= 1'b0;
		end
		else begin
			if (CLKEN && hcc_last) begin
				in_adj <= adj_n;
				interlace_line <= interlace_line_n;
				raster <= raster_n;
				charline <= charline_n;
				if (frame_restart) begin
					parity_frame <= frame_parity_n;
					parity_c9 <= frame_parity_n;
				end
				else if (((ivm_active && c9_done) && !enter_adj) && R9_v_max_line[0])
					parity_c9 <= row_parity_n;
			end
			if ((((((ENABLE & ~nCS) & ~R_nW) & RS) & (addr == 5'd8)) & ((DI[1:0] == 2'b01) | (DI[1:0] == 2'b11))) & (DI[1:0] != R8_interlace))
				parity_c9 <= raster[0];
		end
	reg [13:0] vma;
	reg [13:0] vma_latch;
	wire pointer_frame_origin = (ivm_active | sync_interlace_active ? frame_restart : (!adj_n && (charline_n == 7'd0)) && (raster_n == 5'd0));
	wire [4:0] ra_eff = {raster[4:3], (raster[2:0] + SSCR[6:4]) & 3'd7};
	wire row_latch_done = (ivm_active ? c9_done : ra_eff >= R9_v_max_line);
	wire row_latch_event = (((CLKEN && !in_adj) && !interlace_line) && (hcc == R1_h_displayed)) && row_latch_done;
	wire split_match = (SPLT != 8'd0) && ({charline[4:0], raster[2:0]} == SPLT);
	wire split_adj_end = ((in_adj && adj_end_n) && !ivm_active) && !sync_interlace_active;
	wire split_at_r0 = (((last_charline && (raster == R9_v_max_line)) && !in_adj) && (R5_v_total_adj == 5'd0)) || split_adj_end;
	wire split_latch_event = (CLKEN && split_match) && (hcc == (split_at_r0 ? R0_h_total : R1_h_displayed));
	reg split_held;
	always @(posedge CLOCK)
		if (!nRESET) begin
			vma <= 14'd0;
			vma_latch <= 14'd0;
			split_held <= 1'b0;
		end
		else if (SNA_LOAD) begin
			vma <= {SNA_REGS[96+:6], SNA_REGS[104+:8]};
			vma_latch <= {SNA_REGS[96+:6], SNA_REGS[104+:8]};
			split_held <= 1'b0;
		end
		else if (CLKEN) begin
			if (split_latch_event)
				vma_latch <= SSA;
			else if (row_latch_event)
				vma_latch <= vma;
			if (hcc_last)
				split_held <= 1'b0;
			else if (split_latch_event)
				split_held <= 1'b1;
			if (hcc_last) begin
				if (pointer_frame_origin) begin
					vma <= {R12_start_addr_h[5:0], R13_start_addr_l};
					if (!split_held && !split_latch_event)
						vma_latch <= {R12_start_addr_h[5:0], R13_start_addr_l};
				end
				else if (split_latch_event)
					vma <= SSA;
				else if (!row_latch_event)
					vma <= vma_latch;
			end
			else if (!hcc_last)
				vma <= vma + 14'd1;
		end
	reg hde;
	reg vde;
	reg vde_reseed;
	reg [1:0] dde;
	wire disp_raw = hde & vde;
	always @(posedge CLOCK)
		if (!nRESET) begin
			hde <= 1'b0;
			vde <= 1'b0;
			vde_reseed <= 1'b0;
			dde <= 2'b00;
		end
		else if (SNA_LOAD) begin
			hde <= 1'b0;
			vde <= 1'b0;
			vde_reseed <= 1'b1;
			dde <= 2'b00;
		end
		else if (CLKEN) begin
			if (hcc_last) begin
				hde <= R1_h_displayed != 8'd0;
				if (pointer_frame_origin)
					vde <= charline_n != R6_v_displayed;
				else if (vde_reseed)
					vde <= charline_n < R6_v_displayed;
				else if (charline_n == R6_v_displayed)
					vde <= 1'b0;
				vde_reseed <= 1'b0;
			end
			else if ((hcc + 8'd1) == R1_h_displayed)
				hde <= 1'b0;
			dde <= {dde[0], disp_raw};
		end
	reg in_hsync;
	reg [3:0] hsc;
	reg in_vsync;
	reg [3:0] vsc;
	reg vsync_mid_pending;
	reg vsync_delay_pending;
	wire hsync_start = hcc_next == R2_h_sync_pos;
	wire [3:0] hsc_next = hsc + 4'd1;
	wire hsync_end_hit = hsc_next == R3_h_sync_width;
	wire hsync_end_start_collision = (R3_h_sync_width != 4'd0) && hsync_start;
	always @(posedge CLOCK)
		if (!nRESET) begin
			HSYNC <= 1'b0;
			in_hsync <= 1'b0;
			hsc <= 4'd0;
		end
		else if (SNA_LOAD) begin
			HSYNC <= SNA_HS;
			in_hsync <= SNA_HS;
			hsc <= (SNA_HS ? SNA_HSW : 4'd0);
		end
		else if (CLKEN) begin
			if (in_hsync) begin
				hsc <= hsc_next;
				if (hsync_end_hit && !hsync_end_start_collision) begin
					in_hsync <= 1'b0;
					HSYNC <= 1'b0;
				end
			end
			else if (hsync_start) begin
				in_hsync <= 1'b1;
				HSYNC <= 1'b1;
				hsc <= 4'd0;
			end
		end
	wire vsync_new_c4_start = hcc_last && (frame_restart || (((!in_adj && !interlace_line) && c9_done) && !last_charline));
	wire vsync_new_c4_target = vsync_new_c4_start && (charline_n == R7_v_sync_pos);
	wire vsync_zero_target = (hcc_last && (charline_n == R7_v_sync_pos)) && (raster_n == 5'd0);
	wire vsync_target_seam = vsync_new_c4_target | vsync_zero_target;
	wire vsync_mid_schedule = (vsync_target_seam && (ivm_active || sync_interlace_active)) && !parity_frame;
	wire vsync_delay_schedule = (((vsync_new_c4_target && ivm_active) && parity_frame) && R9_v_max_line[0]) && R7_v_sync_pos[0];
	wire [7:0] vsync_half_hcc = {1'b0, R0_h_total[7:1]};
	wire vsync_half_tick = hcc_next == vsync_half_hcc;
	wire vsync_mid_fire = ((ivm_active || sync_interlace_active) && (vsync_mid_pending | vsync_mid_schedule)) && vsync_half_tick;
	wire vsync_delay_fire = (ivm_active && vsync_delay_pending) && hcc_last;
	wire vsync_seam_fire = (vsync_target_seam && !vsync_mid_schedule) && !vsync_delay_schedule;
	wire vsync_fire = (vsync_seam_fire | vsync_mid_fire) | vsync_delay_fire;
	wire [3:0] vsc_next = vsc + 4'd1;
	wire vsync_width_hit = vsc_next == R3_v_sync_width;
	wire vsync_count_tick = hcc_last;
	always @(posedge CLOCK)
		if (!nRESET) begin
			vsync_mid_pending <= 1'b0;
			vsync_delay_pending <= 1'b0;
		end
		else if (SNA_LOAD) begin
			vsync_mid_pending <= 1'b0;
			vsync_delay_pending <= 1'b0;
		end
		else if (CLKEN) begin
			if (!ivm_active && !sync_interlace_active) begin
				vsync_mid_pending <= 1'b0;
				vsync_delay_pending <= 1'b0;
			end
			else begin
				if (vsync_mid_fire)
					vsync_mid_pending <= 1'b0;
				else if (vsync_target_seam)
					vsync_mid_pending <= vsync_mid_schedule;
				if (vsync_delay_fire)
					vsync_delay_pending <= 1'b0;
				else if (vsync_target_seam)
					vsync_delay_pending <= vsync_delay_schedule;
			end
		end
	always @(posedge CLOCK)
		if (!nRESET) begin
			VSYNC <= 1'b0;
			in_vsync <= 1'b0;
			vsc <= 4'd0;
		end
		else if (SNA_LOAD) begin
			VSYNC <= SNA_VS;
			in_vsync <= SNA_VS;
			vsc <= (SNA_VS ? SNA_VSW : 4'd0);
		end
		else if (CLKEN) begin
			if (in_vsync) begin
				if (vsync_count_tick) begin
					vsc <= vsc_next;
					if (vsync_width_hit) begin
						if (vsync_fire)
							vsc <= 4'd0;
						else begin
							in_vsync <= 1'b0;
							VSYNC <= 1'b0;
						end
					end
				end
			end
			else if (vsync_fire) begin
				in_vsync <= 1'b1;
				VSYNC <= 1'b1;
				vsc <= 4'd0;
			end
		end
	assign DE = (R8_skew == 2'b00 ? disp_raw : (R8_skew == 2'b01 ? dde[0] : (R8_skew == 2'b10 ? dde[1] : 1'b0)));
	assign HCC = hcc;
	assign LINE = charline;
	assign ROW = raster;
	assign ADJ = in_adj;
	assign FIELD = ~parity_frame & R8_interlace[0];
	assign MA = vma;
	assign RA = ra_eff;
	wire s1_bit0 = hcc_equal;
	wire s1_bit1 = ~(hcc == {1'b0, R0_h_total[7:1]});
	wire s1_bit2 = ~((R0_h_total >= R1_h_displayed) && (hcc == (R1_h_displayed - 8'd1)));
	wire s1_bit3 = ~(hcc == R2_h_sync_pos);
	wire [8:0] status1_hsync_end = {1'b0, R2_h_sync_pos} + {5'd0, R3_h_sync_width};
	wire s1_bit4 = ~(hcc == status1_hsync_end);
	wire s1_bit5 = (R3_v_sync_width == 0 ? in_vsync && (vsc != 4'd15) : ~(in_vsync && (vsc == (R3_v_sync_width - 4'd1))));
	wire s1_bit7 = ~(((hcc != R0_h_total) && (vma[7:0] == 8'hff)) || ((hcc == R0_h_total) && (vma_latch[7:0] == 8'h00)));
	wire s2_bit0 = ~(((!in_adj && (charline == R4_v_total)) && (raster == R9_v_max_line)) && hcc_equal);
	wire s2_bit1 = ~(((charline == (R6_v_displayed - 7'd1)) && (raster == R9_v_max_line)) && hcc_equal);
	wire s2_bit2 = ~(((charline == (R7_v_sync_pos - 7'd1)) && (raster == R9_v_max_line)) && hcc_equal);
	reg frame16_toggle;
	wire s2_bit3 = frame16_toggle;
	wire s2_bit4 = (R5_v_total_adj == 5'd0) || ((in_adj && adj_end_n) && hcc_equal);
	wire s2_bit5 = ~(raster == R9_v_max_line);
	wire s2_bit7 = ((raster == R9_v_max_line) && hcc_equal) || ((raster == 5'd0) && (hcc != R0_h_total));
	reg [3:0] frame16_cnt;
	wire frame_origin = (CLKEN && hcc_last) && pointer_frame_origin;
	always @(posedge CLOCK)
		if (!nRESET) begin
			frame16_cnt <= 4'd0;
			frame16_toggle <= 1'b0;
		end
		else if (SNA_LOAD) begin
			frame16_cnt <= 4'd0;
			frame16_toggle <= 1'b0;
		end
		else if (frame_origin) begin
			if (frame16_cnt == 4'd15) begin
				frame16_cnt <= 4'd0;
				frame16_toggle <= ~frame16_toggle;
			end
			else
				frame16_cnt <= frame16_cnt + 4'd1;
		end
	always @(*) begin
		DO = 8'hff;
		if ((ENABLE & ~nCS) & R_nW)
			case (addr[2:0])
				3'd0: DO = {2'b00, R16_pen_h};
				3'd1: DO = R17_pen_l;
				3'd2: DO = {s1_bit7, 1'b1, s1_bit5, s1_bit4, s1_bit3, s1_bit2, s1_bit1, s1_bit0};
				3'd3: DO = {s2_bit7, 1'b0, s2_bit5, s2_bit4, s2_bit3, s2_bit2, s2_bit1, s2_bit0};
				3'd4: DO = R12_start_addr_h;
				3'd5: DO = R13_start_addr_l;
				3'd6: DO = {2'b00, R14_cursor_h};
				3'd7: DO = R15_cursor_l;
			endcase
	end
	reg [3:0] pix_cnt;
	reg [7:0] vid_even;
	reg [7:0] vid_odd;
	reg de_hold;
	reg [1:0] mode_q;
	always @(posedge CLOCK)
		if (!nRESET)
			pix_cnt <= 4'd0;
		else if (SNA_LOAD)
			pix_cnt <= 4'd0;
		else if (PIXEN)
			pix_cnt <= (CLKEN ? 4'd0 : pix_cnt + 4'd1);
	always @(posedge CLOCK)
		if (!nRESET) begin
			vid_even <= 8'd0;
			vid_odd <= 8'd0;
			de_hold <= 1'b0;
		end
		else if (SNA_LOAD) begin
			vid_even <= 8'd0;
			vid_odd <= 8'd0;
			de_hold <= 1'b0;
		end
		else if (PIXEN) begin
			if (CLKEN) begin
				vid_even <= VIDEOD[7:0];
				de_hold <= DE;
			end
			else if (pix_cnt == 4'd7)
				vid_odd <= VIDEOD[15:8];
		end
	always @(posedge CLOCK)
		if (!nRESET)
			mode_q <= 2'b00;
		else if (SNA_LOAD)
			mode_q <= SNA_MODE;
		else if (MODE_UPDATE_EN)
			mode_q <= GAMODE;
	wire [7:0] vbyte = (pix_cnt[3] ? vid_odd : vid_even);
	wire [2:0] s = pix_cnt[2:0];
	reg [3:0] pen_nib;
	always @(*)
		case (mode_q)
			2'b00: pen_nib = (s[2] ? {vbyte[0], vbyte[4], vbyte[2], vbyte[6]} : {vbyte[1], vbyte[5], vbyte[3], vbyte[7]});
			2'b01: pen_nib = {vbyte[{1'b0, ~s[2], ~s[1]}], vbyte[{1'b1, ~s[2], ~s[1]}]};
			2'b10: pen_nib = {3'b000, vbyte[~s]};
			2'b11: pen_nib = (s[2] ? {2'b00, vbyte[2], vbyte[6]} : {2'b00, vbyte[3], vbyte[7]});
		endcase
	function [11:0] legacy_colour;
		input [4:0] hw;
		case (hw)
			5'd0: legacy_colour = 12'h666;
			5'd1: legacy_colour = 12'h666;
			5'd2: legacy_colour = 12'h0f6;
			5'd3: legacy_colour = 12'hff6;
			5'd4: legacy_colour = 12'h006;
			5'd5: legacy_colour = 12'hf06;
			5'd6: legacy_colour = 12'h066;
			5'd7: legacy_colour = 12'hf66;
			5'd8: legacy_colour = 12'hf06;
			5'd9: legacy_colour = 12'hff6;
			5'd10: legacy_colour = 12'hff0;
			5'd11: legacy_colour = 12'hfff;
			5'd12: legacy_colour = 12'hf00;
			5'd13: legacy_colour = 12'hf0f;
			5'd14: legacy_colour = 12'hf60;
			5'd15: legacy_colour = 12'hf6f;
			5'd16: legacy_colour = 12'h006;
			5'd17: legacy_colour = 12'h0f6;
			5'd18: legacy_colour = 12'h0f0;
			5'd19: legacy_colour = 12'h0ff;
			5'd20: legacy_colour = 12'h000;
			5'd21: legacy_colour = 12'h00f;
			5'd22: legacy_colour = 12'h060;
			5'd23: legacy_colour = 12'h06f;
			5'd24: legacy_colour = 12'h606;
			5'd25: legacy_colour = 12'h6f6;
			5'd26: legacy_colour = 12'h6f0;
			5'd27: legacy_colour = 12'h6ff;
			5'd28: legacy_colour = 12'h600;
			5'd29: legacy_colour = 12'h60f;
			5'd30: legacy_colour = 12'h660;
			5'd31: legacy_colour = 12'h66f;
			default: legacy_colour = 12'h000;
		endcase
	endfunction
	reg [3:0] pen_delay [0:14];
	integer p_idx;
	always @(posedge CLOCK)
		if (!nRESET)
			for (p_idx = 0; p_idx < 15; p_idx = p_idx + 1)
				pen_delay[p_idx] <= 4'd0;
		else if (SNA_LOAD)
			for (p_idx = 0; p_idx < 15; p_idx = p_idx + 1)
				pen_delay[p_idx] <= 4'd0;
		else if (PIXEN) begin
			pen_delay[0] <= pen_nib;
			for (p_idx = 1; p_idx < 15; p_idx = p_idx + 1)
				pen_delay[p_idx] <= pen_delay[p_idx - 1];
		end
	wire [3:0] pen_delayed = (SSCR[3:0] == 4'd0 ? pen_nib : pen_delay[SSCR[3:0] - 4'd1]);
	reg de_first_char;
	always @(posedge CLOCK)
		if (!nRESET)
			de_first_char <= 1'b0;
		else if (SNA_LOAD)
			de_first_char <= 1'b0;
		else if (PIXEN && CLKEN)
			de_first_char <= (!de_hold && DE) || (hcc_last && DE);
	wire eff_de = de_hold & ~(SSCR[7] & de_first_char);
	wire [4:0] hw_sel = (eff_de ? INKR_I[pen_delayed * 5+:5] : BORDER_I);
	assign PAL_ADDR = (eff_de ? {1'b0, pen_delayed} : 5'd16);
	wire [11:0] asic_rgb = {PAL_RGB[7:4], PAL_RGB[11:8], PAL_RGB[3:0]};
	wire [11:0] rgb_mux = (PAL_EN ? asic_rgb : legacy_colour(hw_sel));
	reg [14:0] horizontal_blank_history;
	always @(posedge CLOCK)
		if (!nRESET)
			horizontal_blank_history <= 15'd0;
		else if (SNA_LOAD)
			horizontal_blank_history <= {15 {SNA_HS}};
		else if (PIXEN)
			horizontal_blank_history <= {horizontal_blank_history[13:0], HSYNC};
	wire blank = horizontal_blank_history[14];
	assign HWRAP = CLKEN & hcc_last;
	wire show_spr = eff_de & SPR_EN;
	always @(posedge CLOCK)
		if (!nRESET) begin
			RGB_R <= 4'h0;
			RGB_G <= 4'h0;
			RGB_B <= 4'h0;
			PEN <= 5'd0;
		end
		else if (SNA_LOAD) begin
			RGB_R <= 4'h0;
			RGB_G <= 4'h0;
			RGB_B <= 4'h0;
			PEN <= 5'd0;
		end
		else if (PIXEN) begin
			PEN <= {~eff_de, pen_delayed};
			RGB_R <= (blank ? 4'h0 : (show_spr ? SPR_RGB[11:8] : rgb_mux[11:8]));
			RGB_G <= (blank ? 4'h0 : (show_spr ? SPR_RGB[7:4] : rgb_mux[7:4]));
			RGB_B <= (blank ? 4'h0 : (show_spr ? SPR_RGB[3:0] : rgb_mux[3:0]));
		end
endmodule
