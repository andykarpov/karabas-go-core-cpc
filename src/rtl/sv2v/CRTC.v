`default_nettype wire
module CRTC (
	CLOCK,
	CLKEN,
	nCLKEN,
	nRESET,
	CRTC_TYPE,
	ENABLE,
	nCS,
	R_nW,
	RS,
	DI,
	DO,
	SNA_LOAD,
	SNA_ADDR,
	SNA_REGS,
	VSYNC,
	HSYNC,
	HSYNC_RESTART,
	DE,
	FIELD,
	FRAME_FIELD,
	CURSOR,
	MA,
	RA,
	SNAP_ADDR,
	SNAP_REGS,
	SNAP_HCC,
	SNAP_ROW,
	SNAP_LINE,
	SNAP_C5,
	SNAP_IN_ADJ,
	SNAP_HSC,
	SNAP_HSYNC,
	SNAP_VSYNC_R,
	SNAP_VSW_ELAPSED
);
	input CLOCK;
	input CLKEN;
	input nCLKEN;
	input nRESET;
	input CRTC_TYPE;
	input ENABLE;
	input nCS;
	input R_nW;
	input RS;
	input [7:0] DI;
	output reg [7:0] DO;
	input SNA_LOAD;
	input [4:0] SNA_ADDR;
	input [143:0] SNA_REGS;
	output reg VSYNC;
	output reg HSYNC;
	output reg HSYNC_RESTART;
	output wire DE;
	output wire FIELD;
	output wire FRAME_FIELD;
	output wire CURSOR;
	output wire [13:0] MA;
	output wire [4:0] RA;
	output wire [4:0] SNAP_ADDR;
	output wire [127:0] SNAP_REGS;
	output wire [7:0] SNAP_HCC;
	output wire [6:0] SNAP_ROW;
	output wire [4:0] SNAP_LINE;
	output wire [4:0] SNAP_C5;
	output wire SNAP_IN_ADJ;
	output wire [3:0] SNAP_HSC;
	output wire SNAP_HSYNC;
	output wire SNAP_VSYNC_R;
	output wire [3:0] SNAP_VSW_ELAPSED;
	reg field;
	reg [1:0] R8_interlace;
	wire [4:0] interlace = &R8_interlace[1:0];
	assign FIELD = ~field & interlace[0];
	reg frame_interlace;
	assign FRAME_FIELD = ~field & frame_interlace;
	reg [13:0] row_addr_r;
	assign MA = row_addr_r;
	wire e0_ivm_disp;
	wire [4:0] e0_line_vma;
	reg [4:0] line;
	assign RA = (CRTC_TYPE ? line : (e0_ivm_disp ? e0_line_vma : line));
	reg [1:0] dde;
	reg de_second_half;
	wire e0_spurious_border_off;
	reg hde;
	reg vde;
	reg vde_r;
	wire de_unskewed = ((hde & vde) & vde_r) & ~(e0_spurious_border_off & de_second_half);
	wire [3:0] de = {1'b0, dde[1:0], de_unskewed};
	wire [1:0] e0_de_index;
	wire [1:0] e1_de_index;
	assign DE = de[(CRTC_TYPE ? e1_de_index : e0_de_index)];
	reg [7:0] R0_h_total;
	reg [7:0] R1_h_displayed;
	reg [7:0] R2_h_sync_pos;
	reg [3:0] R3_v_sync_width;
	reg [3:0] R3_h_sync_width;
	reg [6:0] R4_v_total;
	reg [4:0] R5_v_total_adj;
	reg [6:0] R6_v_displayed;
	reg [6:0] R7_v_sync_pos;
	reg [1:0] R8_skew;
	reg [4:0] R9_v_max_line;
	reg [1:0] R10_cursor_mode;
	reg [4:0] R10_cursor_start;
	reg [4:0] R11_cursor_end;
	reg [5:0] R12_start_addr_h;
	reg [7:0] R13_start_addr_l;
	reg [5:0] R14_cursor_h;
	reg [7:0] R15_cursor_l;
	wire status_bit5;
	reg [4:0] addr;
	always @(*) begin
		DO = 8'hff;
		if (ENABLE & ~nCS) begin
			if (RS)
				case (addr)
					12: DO = (CRTC_TYPE ? 8'h00 : R12_start_addr_h);
					13: DO = (CRTC_TYPE ? 8'h00 : R13_start_addr_l);
					14: DO = R14_cursor_h;
					15: DO = R15_cursor_l;
					31: DO = (CRTC_TYPE ? 8'hff : 8'h00);
					default: DO = 0;
				endcase
			else if (CRTC_TYPE)
				DO = {2'b00, status_bit5, 5'b00000};
		end
	end
	always @(posedge CLOCK)
		if (SNA_LOAD) begin
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
			{R10_cursor_mode, R10_cursor_start} <= SNA_REGS[86:80] & 7'h7f;
			R11_cursor_end <= SNA_REGS[88+:5];
			R12_start_addr_h <= SNA_REGS[96+:6];
			R13_start_addr_l <= SNA_REGS[104+:8];
			R14_cursor_h <= SNA_REGS[112+:6];
			R15_cursor_l <= SNA_REGS[120+:8];
		end
		else if ((ENABLE & ~nCS) & ~R_nW) begin
			if (~RS)
				addr <= DI[4:0];
			else
				case (addr)
					0: R0_h_total <= DI;
					1: R1_h_displayed <= DI;
					2: R2_h_sync_pos <= DI;
					3: {R3_v_sync_width, R3_h_sync_width} <= DI;
					4: R4_v_total <= DI[6:0];
					5: R5_v_total_adj <= DI[4:0];
					6: R6_v_displayed <= DI[6:0];
					7: R7_v_sync_pos <= DI[6:0];
					8: {R8_skew, R8_interlace} <= {DI[5:4], DI[1:0]};
					9: R9_v_max_line <= DI[4:0];
					10: {R10_cursor_mode, R10_cursor_start} <= DI[6:0];
					11: R11_cursor_end <= DI[4:0];
					12: R12_start_addr_h <= DI[5:0];
					13: R13_start_addr_l <= DI[7:0];
					14: R14_cursor_h <= DI[5:0];
					15: R15_cursor_l <= DI[7:0];
				endcase
		end
	reg in_adj;
	reg [7:0] hcc;
	wire hcc_last = hcc == R0_h_total;
	wire e0_hcc_terminal;
	wire e0_r0_widen_hold;
	wire e1_rfd_r0_extend;
	wire hcc_end = (CRTC_TYPE ? hcc_last : e0_hcc_terminal) & ~(CRTC_TYPE ? e1_rfd_r0_extend : e0_r0_widen_hold);
	wire [7:0] hcc_next = (e0_r0_widen_hold ? hcc : (hcc_end ? 8'h00 : hcc + 1'd1));
	reg [6:0] row;
	reg [4:0] c5;
	reg crtc1_adj_from_row0;
	reg line_last_r;
	reg row_last_r;
	reg frame_adj_r;
	reg parity_frame;
	reg parity_c9;
	reg parity_r6;
	wire e0_r0_frozen;
	wire e0_line_new;
	wire e0_row_frame_last;
	wire e0_row_new;
	wire e0_frame_adj;
	wire e0_c0_line_last;
	wire e0_c0_row_last;
	wire e0_c1_last_line_validate;
	wire e0_in_adj_route;
	wire e0_frozen_row_advance;
	wire e0_r0_widen_step;
	wire e0_hcc2_adj_keep;
	wire e0_reload;
	wire e0_row_addr_save;
	wire e0_field_count_tick;
	wire e0_hsync_off;
	wire e0_vsync_line_fire;
	wire e0_r7_write_fire;
	wire e0_vsync_holdoff;
	wire e0_vsync_c0_2_qualified;
	wire e0_vsync_line_blocked;
	wire e0_vsync_delay_suppress;
	wire e0_vsync_delay_half;
	wire e0_vde_toggle;
	wire e0_r6_vder_write;
	wire e0_r6_vder_value;
	wire e0_pf_write;
	wire e0_pf_value;
	wire e0_pc9_write;
	wire e0_pc9_value;
	wire e0_pr6_write;
	wire e0_pr6_value;
	wire row_r6_landing;
	wire [4:0] e0_line_next;
	wire [4:0] e0_c5_next;
	wire [6:0] e0_row_next;
	wire [3:0] e0_vsc_load;
	reg VSYNC_r;
	reg [3:0] hsc;
	reg vsync_allow;
	reg vsync_active_mid;
	wire e1_pf_value;
	wire e1_pf_write;
	wire vsync_parity = (CRTC_TYPE ? (CLKEN && e1_pf_write ? e1_pf_value : parity_frame) : (CLKEN && e0_pf_write ? e0_pf_value : parity_frame));
	wire vsync_mid = (R8_interlace[0] ? !vsync_parity : field);
	wire vsync_tick_mid = (VSYNC_r ? vsync_active_mid : vsync_mid);
	crtc_type0_engine crtc_type0_engine(
		.CLOCK(CLOCK),
		.CLKEN(CLKEN),
		.nCLKEN(nCLKEN),
		.nRESET(nRESET),
		.CRTC_TYPE(CRTC_TYPE),
		.SNA_LOAD(SNA_LOAD),
		.ENABLE(ENABLE),
		.nCS(nCS),
		.R_nW(R_nW),
		.RS(RS),
		.DI(DI),
		.addr(addr),
		.R0_h_total(R0_h_total),
		.R1_h_displayed(R1_h_displayed),
		.R3_h_sync_width(R3_h_sync_width),
		.R3_v_sync_width(R3_v_sync_width),
		.R4_v_total(R4_v_total),
		.R5_v_total_adj(R5_v_total_adj),
		.R6_v_displayed(R6_v_displayed),
		.R7_v_sync_pos(R7_v_sync_pos),
		.R8_skew(R8_skew),
		.R8_interlace(R8_interlace),
		.R9_v_max_line(R9_v_max_line),
		.hcc(hcc),
		.hcc_next(hcc_next),
		.hcc_last(hcc_last),
		.line(line),
		.row(row),
		.in_adj(in_adj),
		.vsync_mid_phase(vsync_tick_mid),
		.line_last_r(line_last_r),
		.row_last_r(row_last_r),
		.frame_adj_r(frame_adj_r),
		.row_r6_landing(row_r6_landing),
		.VSYNC_r(VSYNC_r),
		.vsync_allow(vsync_allow),
		.hsc(hsc),
		.parity_frame(parity_frame),
		.parity_c9(parity_c9),
		.parity_r6(parity_r6),
		.r0_frozen(e0_r0_frozen),
		.hcc_terminal(e0_hcc_terminal),
		.line_new(e0_line_new),
		.line_next(e0_line_next),
		.c5_next(e0_c5_next),
		.row_frame_last(e0_row_frame_last),
		.row_next(e0_row_next),
		.row_new(e0_row_new),
		.frame_adj(e0_frame_adj),
		.c0_line_last(e0_c0_line_last),
		.c0_row_last(e0_c0_row_last),
		.c1_last_line_validate(e0_c1_last_line_validate),
		.in_adj_route(e0_in_adj_route),
		.frozen_row_advance(e0_frozen_row_advance),
		.hcc2_adj_keep(e0_hcc2_adj_keep),
		.r0_widen_hold(e0_r0_widen_hold),
		.r0_widen_step(e0_r0_widen_step),
		.reload(e0_reload),
		.row_addr_save(e0_row_addr_save),
		.field_count_tick(e0_field_count_tick),
		.hsync_off(e0_hsync_off),
		.de_index(e0_de_index),
		.spurious_border_off(e0_spurious_border_off),
		.vsync_line_fire(e0_vsync_line_fire),
		.vsync_c0_2_qualified(e0_vsync_c0_2_qualified),
		.vsync_line_blocked(e0_vsync_line_blocked),
		.vsync_delay_suppress(e0_vsync_delay_suppress),
		.vsync_delay_half(e0_vsync_delay_half),
		.vsc_load(e0_vsc_load),
		.r7_write_fire(e0_r7_write_fire),
		.vsync_holdoff(e0_vsync_holdoff),
		.vde_toggle(e0_vde_toggle),
		.r6_vder_write(e0_r6_vder_write),
		.r6_vder_value(e0_r6_vder_value),
		.pf_write(e0_pf_write),
		.pf_value(e0_pf_value),
		.pc9_write(e0_pc9_write),
		.pc9_value(e0_pc9_value),
		.pr6_write(e0_pr6_write),
		.pr6_value(e0_pr6_value),
		.ivm_disp(e0_ivm_disp),
		.line_vma(e0_line_vma)
	);
	wire e1_line_last;
	wire e1_line_new;
	wire e1_row_last;
	wire e1_row_frame_last;
	wire e1_row_new;
	wire e1_frame_adj;
	wire e1_adj_from_row0;
	wire e1_reload;
	wire e1_row0_reload;
	wire e1_row_addr_save;
	wire e1_field_count_tick;
	wire e1_hsync_off;
	wire e1_vsync_line_fire;
	wire e1_r7_write_fire;
	wire e1_r6_vde_write;
	wire e1_r6_vde_value;
	wire e1_r7_write_defer;
	wire e1_r7_mid_fire;
	wire e1_r6_vder_write;
	wire e1_r6_vder_value;
	wire e1_status_bit5;
	wire e1_r6_origin;
	wire e1_pc9_write;
	wire e1_pc9_value;
	wire e1_line_poke;
	wire e1_line_poke_bit;
	wire [4:0] e1_line_next;
	wire [4:0] e1_c5_next;
	wire [6:0] e1_row_next;
	wire [3:0] e1_vsc_load;
	crtc_type1_engine crtc_type1_engine(
		.CLOCK(CLOCK),
		.CLKEN(CLKEN),
		.nCLKEN(nCLKEN),
		.nRESET(nRESET),
		.CRTC_TYPE(CRTC_TYPE),
		.SNA_LOAD(SNA_LOAD),
		.ENABLE(ENABLE),
		.nCS(nCS),
		.R_nW(R_nW),
		.RS(RS),
		.DI(DI),
		.addr(addr),
		.R0_h_total(R0_h_total),
		.R1_h_displayed(R1_h_displayed),
		.R3_h_sync_width(R3_h_sync_width),
		.R4_v_total(R4_v_total),
		.R5_v_total_adj(R5_v_total_adj),
		.R6_v_displayed(R6_v_displayed),
		.R7_v_sync_pos(R7_v_sync_pos),
		.R8_interlace(R8_interlace),
		.R9_v_max_line(R9_v_max_line),
		.hcc(hcc),
		.hcc_next(hcc_next),
		.hcc_last(hcc_last),
		.hcc_end(hcc_end),
		.line(line),
		.row(row),
		.c5(c5),
		.in_adj(in_adj),
		.crtc1_adj_from_row0(crtc1_adj_from_row0),
		.VSYNC_r(VSYNC_r),
		.vsync_allow(vsync_allow),
		.hsc(hsc),
		.vde_r(vde_r),
		.parity_frame(parity_frame),
		.parity_c9(parity_c9),
		.vsync_mid(vsync_mid),
		.line_last(e1_line_last),
		.line_new(e1_line_new),
		.line_next(e1_line_next),
		.c5_next(e1_c5_next),
		.row_last(e1_row_last),
		.row_frame_last(e1_row_frame_last),
		.row_next(e1_row_next),
		.row_new(e1_row_new),
		.frame_adj(e1_frame_adj),
		.adj_from_row0(e1_adj_from_row0),
		.reload(e1_reload),
		.row0_reload(e1_row0_reload),
		.row_addr_save(e1_row_addr_save),
		.field_count_tick(e1_field_count_tick),
		.hsync_off(e1_hsync_off),
		.de_index(e1_de_index),
		.vsync_line_fire(e1_vsync_line_fire),
		.vsc_load(e1_vsc_load),
		.r7_write_fire(e1_r7_write_fire),
		.r7_write_defer(e1_r7_write_defer),
		.r7_mid_fire(e1_r7_mid_fire),
		.r6_vde_write(e1_r6_vde_write),
		.r6_vde_value(e1_r6_vde_value),
		.r6_vder_write(e1_r6_vder_write),
		.r6_vder_value(e1_r6_vder_value),
		.rfd_r0_extend(e1_rfd_r0_extend),
		.pf_write(e1_pf_write),
		.pf_value(e1_pf_value),
		.pc9_write(e1_pc9_write),
		.pc9_value(e1_pc9_value),
		.line_poke(e1_line_poke),
		.line_poke_bit(e1_line_poke_bit),
		.status_bit5(e1_status_bit5),
		.r6_origin(e1_r6_origin)
	);
	assign status_bit5 = e1_status_bit5;
	wire r0_frozen = (CRTC_TYPE ? 1'b0 : e0_r0_frozen);
	wire line_new = (CRTC_TYPE ? e1_line_new : e0_line_new);
	wire [4:0] line_next = (CRTC_TYPE ? e1_line_next : e0_line_next);
	wire [4:0] c5_next = (CRTC_TYPE ? e1_c5_next : e0_c5_next);
	wire row_frame_last = (CRTC_TYPE ? e1_row_frame_last : e0_row_frame_last);
	wire [6:0] row_next = (CRTC_TYPE ? e1_row_next : e0_row_next);
	wire row_new = (CRTC_TYPE ? e1_row_new : e0_row_new);
	wire frame_adj = (CRTC_TYPE ? e1_frame_adj : e0_frame_adj);
	wire frame_new = row_new & row_frame_last;
	wire type0_widen_row_step = e0_r0_widen_step && (frame_adj_r || ((hcc == 1) && (hcc_next == 2)));
	wire row_commit = (row_new || e0_frozen_row_advance) || type0_widen_row_step;
	wire [6:0] row_commit_value = (row_new ? row_next : row + 7'd1);
	assign row_r6_landing = row_commit && (row_commit_value == R6_v_displayed);
	wire crtc0_reload = e0_reload;
	wire crtc1_reload = e1_reload;
	wire row_addr_save = (CRTC_TYPE ? e1_row_addr_save : e0_row_addr_save);
	always @(posedge CLOCK)
		if (~nRESET) begin
			hcc <= 0;
			line <= 0;
			row <= 0;
			c5 <= 0;
			in_adj <= 0;
			field <= 0;
			frame_interlace <= 0;
			crtc1_adj_from_row0 <= 0;
			parity_frame <= 0;
			parity_c9 <= 0;
			parity_r6 <= 0;
		end
		else if (CLKEN) begin
			hcc <= hcc_next;
			if (line_new)
				line <= line_next;
			else if (CRTC_TYPE && e1_line_poke)
				line <= {line[4:1], e1_line_poke_bit};
			c5 <= c5_next;
			if (row_commit)
				row <= row_commit_value;
			if ((hcc == 0) && !r0_frozen) begin
				line_last_r <= (CRTC_TYPE ? e1_line_last : e0_c0_line_last);
				row_last_r <= (CRTC_TYPE ? e1_row_last : e0_c0_row_last);
				frame_adj_r <= (CRTC_TYPE ? e1_line_last & e1_row_last : e0_c0_line_last & e0_c0_row_last) & ~in_adj;
			end
			else if (e0_c1_last_line_validate) begin
				line_last_r <= 1;
				row_last_r <= 1;
				frame_adj_r <= 1;
			end
			if (hcc == 2)
				frame_adj_r <= frame_adj_r & e0_hcc2_adj_keep;
			if (e0_in_adj_route)
				in_adj <= 1;
			if (e0_frozen_row_advance) begin
				if (row == R4_v_total)
					in_adj <= 1;
			end
			if (type0_widen_row_step) begin
				if (frame_adj_r) begin
					in_adj <= 1;
					line_last_r <= 0;
					row_last_r <= 0;
					frame_adj_r <= 0;
				end
			end
			if (((CRTC_TYPE && line_new) && !row_new) && frame_adj) begin
				in_adj <= 1;
				if (e1_adj_from_row0)
					crtc1_adj_from_row0 <= 1;
			end
			if (row_new) begin
				if (frame_adj) begin
					in_adj <= 1;
					if (e1_adj_from_row0)
						crtc1_adj_from_row0 <= 1;
				end
				else if (frame_new) begin
					in_adj <= 0;
					field <= ~field & R8_interlace[0];
					frame_interlace <= interlace[0];
					crtc1_adj_from_row0 <= 0;
				end
				else if ((CRTC_TYPE && in_adj) && (row_next != 1))
					crtc1_adj_from_row0 <= 0;
			end
			if (CRTC_TYPE) begin
				if (e1_pf_write)
					parity_frame <= e1_pf_value;
				if (e1_pc9_write)
					parity_c9 <= e1_pc9_value;
			end
			else begin
				if (e0_pf_write)
					parity_frame <= e0_pf_value;
				if (e0_pc9_write)
					parity_c9 <= e0_pc9_value;
				if (e0_pr6_write)
					parity_r6 <= e0_pr6_value;
			end
		end
	reg [13:0] row_addr;
	wire reg_data_write = ((ENABLE & ~nCS) & ~R_nW) & RS;
	wire [5:0] r12_effective = (SNA_LOAD ? SNA_REGS[96+:6] : (reg_data_write & (addr == 5'd12) ? DI[5:0] : R12_start_addr_h));
	wire [7:0] r13_effective = (SNA_LOAD ? SNA_REGS[104+:8] : (reg_data_write & (addr == 5'd13) ? DI : R13_start_addr_l));
	always @(posedge CLOCK)
		if (CLKEN) begin
			if (row_addr_save)
				row_addr <= row_addr_r;
			if (line_new & !row_addr_save)
				row_addr_r <= row_addr;
			if (!hcc_end)
				row_addr_r <= row_addr_r + 1'd1;
			if (crtc0_reload) begin
				row_addr <= {R12_start_addr_h, R13_start_addr_l};
				row_addr_r <= {R12_start_addr_h, R13_start_addr_l};
			end
			if (crtc1_reload)
				row_addr_r <= {R12_start_addr_h, R13_start_addr_l};
			if (e1_row0_reload)
				row_addr_r <= {r12_effective, r13_effective};
		end
	reg [6:0] hsync_char_phase;
	reg [6:0] hsync_start_phase;
	reg [6:0] hsync_off_count;
	reg hsync_off_pending;
	reg hsync_phaseful;
	reg type1_hsync_start_pending;
	reg [1:0] type1_hsync_start_count;
	reg type0_hsync_restart_pending;
	reg [3:0] type0_hsync_restart_count;
	reg r2_jit_pending;
	reg jit_on_pending;
	reg [3:0] jit_on_count;
	reg hsync_type_d;
	reg register_write_d;
	wire hsync_on = (hcc == R2_h_sync_pos) && (R3_h_sync_width != 0);
	wire type1_hsync_overflow = (hcc == R2_h_sync_pos) && (R3_h_sync_width != 0);
	wire hsync_off = (CRTC_TYPE ? e1_hsync_off && !type1_hsync_overflow : e0_hsync_off);
	reg type1_restart_seen;
	reg type1_restart_pending;
	reg [6:0] type1_restart_count;
	wire type1_restart_due = ((HSYNC && CRTC_TYPE) && e1_hsync_off) && type1_hsync_overflow;
	always @(posedge CLOCK)
		if ((!nRESET || SNA_LOAD) || !CRTC_TYPE) begin
			HSYNC_RESTART <= 0;
			type1_restart_seen <= 0;
			type1_restart_pending <= 0;
			type1_restart_count <= 0;
		end
		else begin
			HSYNC_RESTART <= 0;
			if (!type1_restart_due)
				type1_restart_seen <= 0;
			if (type1_restart_pending) begin
				if (type1_restart_count == 0) begin
					HSYNC_RESTART <= 1;
					type1_restart_pending <= 0;
				end
				else
					type1_restart_count <= type1_restart_count - 1'd1;
			end
			else if (type1_restart_due && !type1_restart_seen) begin
				type1_restart_seen <= 1;
				if (hsync_phaseful && (hsync_start_phase != 0)) begin
					type1_restart_pending <= 1;
					type1_restart_count <= hsync_start_phase - 1'd1;
				end
				else
					HSYNC_RESTART <= 1;
			end
		end
	wire register_write = ((ENABLE & RS) & ~nCS) & ~R_nW;
	wire r2_jit_write = ((((register_write & ~register_write_d) & (addr == 5'd2)) & (hcc == DI)) & (R2_h_sync_pos != DI)) & (R3_h_sync_width != 0);
	wire type0_r3_terminal_write = (((((((register_write & ~register_write_d) & !CRTC_TYPE) & (addr == 5'd3)) & HSYNC) & (hcc == R2_h_sync_pos)) & (hsc == R3_h_sync_width)) & (DI[3:0] != 0)) & (DI[3:0] != R3_h_sync_width);
	always @(posedge CLOCK)
		if (~nRESET) begin
			hsc <= 0;
			hde <= 0;
			HSYNC <= 0;
			hsync_char_phase <= 0;
			hsync_start_phase <= 0;
			hsync_off_count <= 0;
			hsync_off_pending <= 0;
			hsync_phaseful <= 0;
			type1_hsync_start_pending <= 0;
			type1_hsync_start_count <= 0;
			type0_hsync_restart_pending <= 0;
			type0_hsync_restart_count <= 0;
			r2_jit_pending <= 0;
			jit_on_pending <= 0;
			jit_on_count <= 0;
			hsync_type_d <= CRTC_TYPE;
			register_write_d <= 0;
		end
		else begin
			register_write_d <= register_write;
			hsync_type_d <= CRTC_TYPE;
			if (CLKEN)
				hsync_char_phase <= 0;
			else
				hsync_char_phase <= hsync_char_phase + 1'd1;
			if (r2_jit_write)
				r2_jit_pending <= 1;
			if (!CRTC_TYPE)
				type1_hsync_start_pending <= 0;
			if (SNA_LOAD || CRTC_TYPE) begin
				type0_hsync_restart_pending <= 0;
				type0_hsync_restart_count <= 0;
			end
			else if (type0_r3_terminal_write) begin
				type0_hsync_restart_pending <= 1;
				type0_hsync_restart_count <= 4'd13;
			end
			if (hsync_off_pending) begin
				if (hsync_off_count == 0) begin
					HSYNC <= 0;
					hsync_off_pending <= 0;
					hsync_phaseful <= 0;
				end
				else
					hsync_off_count <= hsync_off_count - 1'd1;
			end
			else if (hsync_off) begin
				if ((HSYNC && hsync_phaseful) && (hsync_start_phase != 0)) begin
					hsync_off_pending <= 1;
					hsync_off_count <= hsync_start_phase - 1'd1;
				end
				else begin
					HSYNC <= 0;
					hsync_phaseful <= 0;
				end
			end
			else if (!HSYNC) begin
				if (jit_on_pending) begin
					if ((!hsync_on || SNA_LOAD) || (CRTC_TYPE != hsync_type_d)) begin
						jit_on_pending <= 0;
						jit_on_count <= 0;
					end
					else if (jit_on_count == 0) begin
						HSYNC <= 1;
						jit_on_pending <= 0;
					end
					else
						jit_on_count <= jit_on_count - 1'd1;
				end
				else if ((!SNA_LOAD && !CRTC_TYPE) && type0_hsync_restart_pending) begin
					if (type0_hsync_restart_count == 0) begin
						HSYNC <= 1;
						hsync_phaseful <= 0;
						hsync_start_phase <= 0;
						type0_hsync_restart_pending <= 0;
					end
					else
						type0_hsync_restart_count <= type0_hsync_restart_count - 1'd1;
				end
				else if (r2_jit_pending && hsync_on) begin
					jit_on_pending <= 1;
					jit_on_count <= 7;
					hsync_phaseful <= CRTC_TYPE;
					hsync_start_phase <= (CRTC_TYPE ? 7'd4 : 7'd0);
					r2_jit_pending <= 0;
					type1_hsync_start_pending <= 0;
				end
				else if (CRTC_TYPE) begin
					if (type1_hsync_start_pending) begin
						if (type1_hsync_start_count == 0) begin
							HSYNC <= 1;
							hsync_phaseful <= 1;
							hsync_start_phase <= hsync_char_phase;
							type1_hsync_start_pending <= 0;
						end
						else
							type1_hsync_start_count <= type1_hsync_start_count - 1'd1;
					end
					else if (hsync_on) begin
						type1_hsync_start_pending <= 1;
						type1_hsync_start_count <= 3;
					end
				end
				else if (hsync_on) begin
					HSYNC <= 1;
					hsync_phaseful <= 0;
				end
			end
			if (CLKEN && (hcc != R2_h_sync_pos))
				r2_jit_pending <= 0;
			if (SNA_LOAD || (CRTC_TYPE != hsync_type_d)) begin
				r2_jit_pending <= 0;
				jit_on_pending <= 0;
				jit_on_count <= 0;
				type1_hsync_start_pending <= 0;
			end
			if (((((ENABLE & RS) & ~nCS) & ~R_nW) & (addr == 5'd1)) & (hcc == DI))
				hde <= 0;
			if (CLKEN) begin
				if (line_new)
					hde <= 1;
				if (hcc_next == R1_h_displayed)
					hde <= 0;
				if (HSYNC)
					hsc <= hsc + 1'd1;
				else
					hsc <= 0;
			end
		end
	reg type0_r6_zero_origin_border;
	wire r7_write_hit = (((ENABLE & RS) & ~nCS) & ~R_nW) & (addr == 5'd7);
	wire vsync_origin_match = (r7_write_hit ? DI[6:0] : R7_v_sync_pos) == 0;
	wire vsync_line_fire = (frame_new ? vsync_origin_match && (CRTC_TYPE || e0_vsync_c0_2_qualified) : (CRTC_TYPE ? e1_vsync_line_fire : e0_vsync_line_fire));
	reg vsync_mid_arm;
	reg [3:0] vsw_elapsed;
	wire vsync_line_blocked = (frame_new && !vsync_tick_mid ? vsync_origin_match && !e0_vsync_c0_2_qualified : e0_vsync_line_blocked);
	wire vsync_count_tick = CLKEN && (vsync_tick_mid ? (CRTC_TYPE ? e1_field_count_tick : e0_field_count_tick) : line_new);
	wire vsync_holdoff = e0_vsync_holdoff;
	wire vsync_type0_mid_fire = ((((row == R7_v_sync_pos) && !line) && e0_vsync_c0_2_qualified) && !e0_vsync_delay_suppress) || e0_vsync_delay_half;
	wire vsync_fire = ((vsync_allow && (vsync_mid == vsync_tick_mid)) && (vsync_mid ? (CRTC_TYPE ? (R8_interlace[0] ? vsync_mid_arm : (row == R7_v_sync_pos) && !line) : vsync_type0_mid_fire) : vsync_line_fire)) || e1_r7_mid_fire;
	always @(posedge CLOCK)
		if (~nRESET | SNA_LOAD)
			vsync_mid_arm <= 0;
		else if (CLKEN) begin
			if (line_new)
				vsync_mid_arm <= vsync_mid && vsync_line_fire;
			else if (vsync_count_tick && vsync_mid_arm)
				vsync_mid_arm <= 0;
		end
	wire [3:0] vsc_load = (CRTC_TYPE ? e1_vsc_load : e0_vsc_load);
	wire r7_write_fire = (CRTC_TYPE ? e1_r7_write_fire : e0_r7_write_fire);
	wire type0_r6_zero_origin_r1_hit = ((((!CRTC_TYPE && !row_new) && (row == 0)) && (line == 0)) && (R6_v_displayed == 0)) && (hcc_next == R1_h_displayed);
	always @(posedge CLOCK)
		if ((~nRESET | SNA_LOAD) | CRTC_TYPE)
			type0_r6_zero_origin_border <= 0;
		else if (CLKEN) begin
			if (row_new)
				type0_r6_zero_origin_border <= 0;
			else if (type0_r6_zero_origin_r1_hit)
				type0_r6_zero_origin_border <= 1;
		end
	reg [3:0] type1_vsync_publication;
	reg vsync_publication_type;
	always @(posedge CLOCK)
		if (!nRESET) begin
			VSYNC <= (CRTC_TYPE ? 1'b0 : VSYNC_r);
			type1_vsync_publication <= 0;
			vsync_publication_type <= CRTC_TYPE;
		end
		else begin
			vsync_publication_type <= CRTC_TYPE;
			if (SNA_LOAD || (CRTC_TYPE != vsync_publication_type)) begin
				VSYNC <= VSYNC_r;
				type1_vsync_publication <= {4 {VSYNC_r}};
			end
			else begin
				type1_vsync_publication <= {type1_vsync_publication[2:0], VSYNC_r};
				VSYNC <= (CRTC_TYPE ? type1_vsync_publication[3] : VSYNC_r);
			end
		end
	always @(posedge CLOCK) begin : sv2v_autoblock_1
		reg [3:0] vsc;
		if (~nRESET) begin
			vsc <= 0;
			vsw_elapsed <= 4'd0;
			vde <= 0;
			vde_r <= 0;
			VSYNC_r <= 0;
			vsync_active_mid <= 0;
			vsync_allow <= 1;
		end
		else if (CLKEN) begin
			if (e0_vde_toggle && !type0_r6_zero_origin_border) begin
				vde <= ~vde;
				vde_r <= ~vde_r;
			end
			if ((((!CRTC_TYPE && !VSYNC_r) && line_new) && (line_next == 0)) && ((row_new ? row_next : row) != (r7_write_hit ? DI[6:0] : R7_v_sync_pos)))
				vsync_allow <= 1;
			if (row_new) begin
				if ((frame_new & (row != 0)) | (row_next != row))
					vsync_allow <= 1;
				if (frame_new | (CRTC_TYPE & e1_r6_origin)) begin
					vde <= 1;
					vde_r <= 1;
				end
			end
			if (row_r6_landing && (row_new ? !(frame_new && !CRTC_TYPE) : !((row_commit_value == 0) && (line == 0)))) begin
				vde <= 0;
				vde_r <= 0;
			end
			if (type0_r6_zero_origin_r1_hit) begin
				vde <= 0;
				vde_r <= 0;
			end
			if (vsync_count_tick) begin
				if ((!CRTC_TYPE && vsync_allow) && vsync_line_blocked)
					vsync_allow <= 0;
				if (vsync_holdoff)
					;
				else if (vsc) begin
					vsc <= vsc - 1'd1;
					vsw_elapsed <= vsw_elapsed + 4'd1;
				end
				else if (vsync_fire) begin
					VSYNC_r <= 1;
					vsync_active_mid <= vsync_mid;
					vsync_allow <= 0;
					vsc <= vsc_load;
					vsw_elapsed <= 4'd0;
				end
				else
					VSYNC_r <= 0;
			end
		end
		else if (nCLKEN) begin
			if (e0_vde_toggle && !type0_r6_zero_origin_border) begin
				vde <= ~vde;
				vde_r <= ~vde_r;
			end
		end
		if (r7_write_hit) begin
			if (row != DI[6:0]) begin
				if (CRTC_TYPE || VSYNC_r)
					vsync_allow <= 1;
			end
			else begin
				vsync_allow <= 0;
				if (r7_write_fire && !e1_r7_write_defer) begin
					VSYNC_r <= 1;
					vsync_active_mid <= vsync_mid;
					vsc <= vsc_load;
					vsw_elapsed <= 4'd0;
				end
			end
		end
		if (((((nCLKEN & ENABLE) & RS) & ~nCS) & ~R_nW) & (addr == 5'd6)) begin
			if (CRTC_TYPE) begin
				if (e1_r6_vder_write)
					vde_r <= e1_r6_vder_value;
				if (e1_r6_vde_write)
					vde <= e1_r6_vde_value;
			end
			else if (e0_r6_vder_write)
				vde_r <= e0_r6_vder_value;
		end
	end
	always @(posedge CLOCK)
		if (~nRESET)
			de_second_half <= 0;
		else if (CLKEN)
			de_second_half <= 0;
		else if (nCLKEN)
			de_second_half <= 1;
	always @(posedge CLOCK)
		if (CLKEN)
			dde <= {dde[0], de[0]};
	reg cursor_line;
	assign CURSOR = ((hde & vde) & (MA == {R14_cursor_h, R15_cursor_l})) & cursor_line;
	always @(posedge CLOCK)
		if (~nRESET)
			cursor_line <= 0;
		else if (CLKEN) begin
			if (line == R10_cursor_start)
				cursor_line <= 1;
			else if (line == R11_cursor_end)
				cursor_line <= 0;
		end
	assign SNAP_ADDR = addr;
	assign SNAP_REGS = {R15_cursor_l, 2'b00, R14_cursor_h, R13_start_addr_l, 2'b00, R12_start_addr_h, 3'b000, R11_cursor_end, 1'b0, R10_cursor_mode, R10_cursor_start, 3'b000, R9_v_max_line, 2'b00, R8_skew, 2'b00, R8_interlace, 1'b0, R7_v_sync_pos, 1'b0, R6_v_displayed, 3'b000, R5_v_total_adj, 1'b0, R4_v_total, R3_v_sync_width, R3_h_sync_width, R2_h_sync_pos, R1_h_displayed, R0_h_total};
	assign SNAP_HCC = hcc;
	assign SNAP_ROW = row;
	assign SNAP_LINE = line;
	assign SNAP_C5 = c5;
	assign SNAP_IN_ADJ = in_adj;
	assign SNAP_HSC = hsc;
	assign SNAP_HSYNC = HSYNC;
	assign SNAP_VSYNC_R = VSYNC_r;
	assign SNAP_VSW_ELAPSED = vsw_elapsed;
endmodule
