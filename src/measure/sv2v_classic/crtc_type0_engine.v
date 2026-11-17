module crtc_type0_engine (
	CLOCK,
	CLKEN,
	nCLKEN,
	nRESET,
	CRTC_TYPE,
	SNA_LOAD,
	ENABLE,
	nCS,
	R_nW,
	RS,
	DI,
	addr,
	R0_h_total,
	R1_h_displayed,
	R3_h_sync_width,
	R3_v_sync_width,
	R4_v_total,
	R5_v_total_adj,
	R6_v_displayed,
	R7_v_sync_pos,
	R8_skew,
	R8_interlace,
	R9_v_max_line,
	hcc,
	hcc_next,
	hcc_last,
	line,
	row,
	in_adj,
	vsync_mid_phase,
	line_last_r,
	row_last_r,
	frame_adj_r,
	row_r6_landing,
	VSYNC_r,
	vsync_allow,
	hsc,
	parity_frame,
	parity_c9,
	parity_r6,
	r0_frozen,
	hcc_terminal,
	line_new,
	line_next,
	c5_next,
	row_frame_last,
	row_next,
	row_new,
	frame_adj,
	c0_line_last,
	c0_row_last,
	c1_last_line_validate,
	in_adj_route,
	frozen_row_advance,
	hcc2_adj_keep,
	r0_widen_hold,
	r0_widen_step,
	reload,
	row_addr_save,
	field_count_tick,
	hsync_off,
	de_index,
	spurious_border_off,
	vsync_line_fire,
	vsync_c0_2_qualified,
	vsync_line_blocked,
	vsync_delay_suppress,
	vsync_delay_half,
	vsc_load,
	r7_write_fire,
	vsync_holdoff,
	vde_toggle,
	r6_vder_write,
	r6_vder_value,
	pf_write,
	pf_value,
	pc9_write,
	pc9_value,
	pr6_write,
	pr6_value,
	ivm_disp,
	line_vma
);
	input CLOCK;
	input CLKEN;
	input nCLKEN;
	input nRESET;
	input CRTC_TYPE;
	input SNA_LOAD;
	input ENABLE;
	input nCS;
	input R_nW;
	input RS;
	input [7:0] DI;
	input [4:0] addr;
	input [7:0] R0_h_total;
	input [7:0] R1_h_displayed;
	input [3:0] R3_h_sync_width;
	input [3:0] R3_v_sync_width;
	input [6:0] R4_v_total;
	input [4:0] R5_v_total_adj;
	input [6:0] R6_v_displayed;
	input [6:0] R7_v_sync_pos;
	input [1:0] R8_skew;
	input [1:0] R8_interlace;
	input [4:0] R9_v_max_line;
	input [7:0] hcc;
	input [7:0] hcc_next;
	input hcc_last;
	input [4:0] line;
	input [6:0] row;
	input in_adj;
	input vsync_mid_phase;
	input line_last_r;
	input row_last_r;
	input frame_adj_r;
	input row_r6_landing;
	input VSYNC_r;
	input vsync_allow;
	input [3:0] hsc;
	input parity_frame;
	input parity_c9;
	input parity_r6;
	output wire r0_frozen;
	output wire hcc_terminal;
	output wire line_new;
	output wire [4:0] line_next;
	output wire [4:0] c5_next;
	output wire row_frame_last;
	output wire [6:0] row_next;
	output wire row_new;
	output wire frame_adj;
	output wire c0_line_last;
	output wire c0_row_last;
	output wire c1_last_line_validate;
	output wire in_adj_route;
	output wire frozen_row_advance;
	output wire hcc2_adj_keep;
	output wire r0_widen_hold;
	output wire r0_widen_step;
	output wire reload;
	output wire row_addr_save;
	output wire field_count_tick;
	output wire hsync_off;
	output wire [1:0] de_index;
	output wire spurious_border_off;
	output wire vsync_line_fire;
	output wire vsync_c0_2_qualified;
	output wire vsync_line_blocked;
	output wire vsync_delay_suppress;
	output wire vsync_delay_half;
	output wire [3:0] vsc_load;
	output wire r7_write_fire;
	output wire vsync_holdoff;
	output wire vde_toggle;
	output wire r6_vder_write;
	output wire r6_vder_value;
	output wire pf_write;
	output wire pf_value;
	output wire pc9_write;
	output wire pc9_value;
	output wire pr6_write;
	output wire pr6_value;
	output wire ivm_disp;
	output wire [4:0] line_vma;
	wire register_write = ((ENABLE & ~nCS) & ~R_nW) & RS;
	reg type0_r0_eq_kept;
	wire [7:0] type0_r0_at_sample = (register_write && (addr == 5'd0) ? DI : R0_h_total);
	always @(posedge CLOCK)
		if (((!nRESET || SNA_LOAD) || CRTC_TYPE) || CLKEN)
			type0_r0_eq_kept <= 0;
		else if (nCLKEN)
			type0_r0_eq_kept <= (hcc == type0_r0_at_sample) && (type0_r0_at_sample != 8'd1);
	assign hcc_terminal = hcc_last || (((nRESET && !SNA_LOAD) && !CRTC_TYPE) && type0_r0_eq_kept);
	reg ivm_disp_r;
	reg tog_line;
	reg tog_enter_line;
	wire r8_write_hit_t0 = ((((!CRTC_TYPE & ENABLE) & RS) & ~nCS) & ~R_nW) & (addr == 5'd8);
	wire r8_toggle_write_t0 = r8_write_hit_t0 && ((DI[1:0] == 2'b11) != ivm_disp_r);
	wire type0_seam = CLKEN && (hcc == 0);
	always @(posedge CLOCK)
		if ((~nRESET | SNA_LOAD) | CRTC_TYPE) begin
			ivm_disp_r <= 0;
			tog_line <= 0;
			tog_enter_line <= 0;
		end
		else begin
			if (type0_seam) begin
				ivm_disp_r <= R8_interlace == 2'b11;
				tog_line <= 0;
			end
			if (r8_toggle_write_t0) begin
				tog_line <= 1;
				tog_enter_line <= DI[1:0] == 2'b11;
			end
		end
	wire type0_ivm_turn_on = (type0_seam && !ivm_disp_r) && (R8_interlace == 2'b11);
	wire type0_pc9_odd_update = (R9_v_max_line[0] && ivm_disp_r) && (pf_write || (row_new && !in_adj));
	assign pc9_write = type0_ivm_turn_on || type0_pc9_odd_update;
	assign pc9_value = (type0_ivm_turn_on ? parity_frame : (pf_write ? parity_r6 : row_next[0] ^ parity_frame));
	assign ivm_disp = ivm_disp_r;
	assign line_vma = {line[3:0], parity_c9};
	reg type0_r4_adjust_switch;
	reg type0_r9_live_compare;
	reg type0_r9_at_r0_pending;
	reg type0_c0_1_adjust;
	reg type0_r0_zero_entry_consumed;
	reg type0_zero_adj_entry;
	reg type0_r5_adjust_override;
	reg [4:0] type0_r5_adjust_target;
	reg type0_r0_widen_pending;
	wire type0_r4_window_write;
	wire type0_r4_switch_write;
	wire type0_r9_compare_write;
	wire type0_r9_pending_r4_cancel = (((type0_r9_live_compare && in_adj) && register_write) && (addr == 5'd4)) && (DI[6:0] != row);
	wire type0_r4_switch_active = (type0_r4_adjust_switch | type0_r4_switch_write) | type0_r9_pending_r4_cancel;
	wire type0_r9_compare_active = (type0_r9_live_compare | type0_r9_compare_write) & ~type0_r4_switch_active;
	wire type0_c0_1_break_write = ((((!CRTC_TYPE && register_write) && (hcc == 1)) && frame_adj_r) && !in_adj) && (((addr == 5'd4) && (DI[6:0] != row)) || ((addr == 5'd9) && (DI[4:0] != line)));
	wire type0_c0_1_adjust_active = type0_c0_1_adjust | type0_c0_1_break_write;
	wire type0_c0_1_r9_owner = type0_r9_compare_active || (((type0_c0_1_break_write && (addr == 5'd9)) && (row == R4_v_total)) && !type0_r4_switch_active);
	wire type0_c0_1_r5_owner = type0_c0_1_adjust_active && !type0_c0_1_r9_owner;
	wire type0_r0_widen_write_eligible = (((((((((nRESET && !SNA_LOAD) && !CRTC_TYPE) && register_write) && (addr == 5'd0)) && (hcc == 1)) && (R0_h_total == 1)) && (DI > 1)) && !in_adj) && (R5_v_total_adj == 0)) && (R8_interlace == 0);
	wire type0_r0_widen_write_accept = type0_r0_widen_write_eligible && frame_adj_r;
	reg type0_r0_widen_write_pending;
	wire type0_r0_widen_accept = CLKEN && type0_r0_widen_write_accept;
	always @(posedge CLOCK)
		if (((!nRESET || SNA_LOAD) || CRTC_TYPE) || CLKEN)
			type0_r0_widen_write_pending <= 0;
		else if (type0_r0_widen_write_accept || (type0_r0_widen_write_eligible && (line == R9_v_max_line)))
			type0_r0_widen_write_pending <= 1;
	assign r0_widen_hold = type0_r0_widen_accept;
	assign r0_widen_step = ((type0_r0_widen_pending || type0_r0_widen_write_pending) && !SNA_LOAD) && !CRTC_TYPE;
	wire r0_frozen_w = hcc_terminal && !hcc;
	assign r0_frozen = !CRTC_TYPE && r0_frozen_w;
	wire [4:0] crtc0_line_max = (in_adj ? R5_v_total_adj - 1'd1 : R9_v_max_line);
	wire [5:0] type0_limit_addend = (tog_line ? (tog_enter_line ? {5'b00000, parity_frame} : 6'd0) : (ivm_disp_r ? {4'b0000, parity_c9 ^ R9_v_max_line[0]} : 6'd0));
	wire [5:0] type0_limit_target6 = {1'b0, R9_v_max_line} + type0_limit_addend;
	wire [4:0] type0_limit_value = (ivm_disp_r ? line_vma : line);
	wire type0_ivm_limit = {1'b0, type0_limit_value} == type0_limit_target6;
	wire line_last = (in_adj && !type0_r9_compare_active ? line == crtc0_line_max : type0_ivm_limit);
	wire type0_r5_write = (!CRTC_TYPE && register_write) && (addr == 5'd5);
	wire type0_r5_window_write = (type0_r5_write && (hcc <= 2)) && (in_adj || type0_c0_1_r5_owner);
	wire [4:0] type0_r5_adjust_target_effective = (type0_r5_window_write ? DI[4:0] - 1'd1 : type0_r5_adjust_target);
	wire [4:0] type0_effective_r5 = (type0_r5_write ? DI[4:0] : R5_v_total_adj);
	wire type0_r5_override_active = (type0_r5_adjust_override | type0_r5_window_write) & (in_adj || type0_c0_1_r5_owner);
	wire type0_zero_adj_entry_active = type0_zero_adj_entry & ~((type0_r5_write && (hcc <= 2)) && |DI[4:0]);
	wire [4:0] type0_adjust_line_max = (type0_r5_override_active ? type0_r5_adjust_target_effective : type0_effective_r5 - 1'd1);
	wire type0_r9_at_r0_write;
	wire type0_r9_at_r0_active = type0_r9_at_r0_pending | type0_r9_at_r0_write;
	wire type0_live_line_last = type0_ivm_limit;
	wire type0_last_line_armed = line_last_r & row_last_r;
	wire type0_c0_1_r5_end = type0_c0_1_r5_owner && (line == type0_adjust_line_max);
	wire type0_c0_1_r9_match = ((type0_c0_1_adjust && type0_c0_1_r9_owner) && !type0_r9_at_r0_active) && type0_live_line_last;
	wire type0_rollover_line_last = (type0_c0_1_adjust_active ? type0_c0_1_r5_end | type0_c0_1_r9_match : (c1_last_line_validate ? 1'b1 : (type0_r9_at_r0_active ? line == type0_adjust_line_max : (type0_r4_switch_active ? line == type0_adjust_line_max : (type0_r9_compare_active ? type0_live_line_last : (type0_r5_override_active ? (line == type0_adjust_line_max) | type0_zero_adj_entry_active : (in_adj | type0_last_line_armed ? line_last_r : type0_live_line_last)))))));
	wire type0_r9_zero_adjust_end = (((in_adj | type0_c0_1_r9_match) && type0_r9_compare_active) && type0_rollover_line_last) && (type0_adjust_line_max == 5'd31);
	wire type0_adjust_end = type0_r9_zero_adjust_end | type0_c0_1_r5_end;
	wire type0_rollover_row_last = (type0_r9_at_r0_active ? line_last_r : type0_rollover_line_last);
	assign line_new = (hcc_terminal && !r0_frozen_w) && !type0_r0_widen_accept;
	wire type0_add_armed = R8_interlace[0] && parity_r6;
	reg type0_add_line_active;
	wire type0_adjustment_selected = type0_c0_1_adjust_active | (hcc == 2 ? frame_adj_r & |type0_effective_r5 : frame_adj_r);
	wire crtc0_row_frame_last = ((type0_last_line_armed | in_adj) & (~type0_adjustment_selected | type0_adjust_end)) & (~type0_r9_compare_active | type0_r9_zero_adjust_end);
	wire type0_frame_end_raw = row_new & crtc0_row_frame_last;
	wire type0_add_intercept = (type0_frame_end_raw && !type0_add_line_active) && type0_add_armed;
	assign line_next = (type0_add_intercept ? R5_v_total_adj : (type0_rollover_line_last ? 5'd0 : line + 5'd1));
	assign c5_next = 5'd0;
	wire row_last_w = row == R4_v_total;
	assign frame_adj = (((type0_adjustment_selected | type0_r9_compare_active) & ~type0_adjust_end) | c1_last_line_validate) | type0_add_intercept;
	assign row_frame_last = crtc0_row_frame_last & ~type0_add_intercept;
	assign row_next = (type0_add_intercept ? (in_adj ? row : row + 7'd1) : (row_frame_last ? 7'd0 : row + 1'd1));
	assign row_new = line_new & type0_rollover_row_last;
	wire frame_new_w = row_new & row_frame_last;
	assign pf_write = frame_new_w;
	assign pf_value = parity_r6;
	assign pr6_write = ((row_r6_landing && !frame_new_w) && !in_adj) && (row_new || !((R6_v_displayed == 0) && (line == 0)));
	assign pr6_value = parity_frame ^ 1'd1;
	wire type0_r4_at_c0_write = (register_write && (addr == 5'd4)) && (hcc < 2);
	wire type0_r9_at_c0_write = (register_write && (addr == 5'd9)) && (hcc < 2);
	wire type0_r5_at_c0_write = type0_r5_write && (hcc == 0);
	wire [6:0] type0_c0_r4 = (type0_r4_at_c0_write ? DI[6:0] : R4_v_total);
	wire [4:0] type0_c0_r9 = (type0_r9_at_c0_write ? DI[4:0] : R9_v_max_line);
	wire [4:0] type0_c0_r5 = (type0_r5_at_c0_write ? DI[4:0] : R5_v_total_adj);
	wire [4:0] type0_c0_adjust_line_max = type0_c0_r5 - 1'd1;
	wire type0_c0_zero_adj_entry = type0_zero_adj_entry & ~(type0_r5_at_c0_write & |DI[4:0]);
	wire type0_seam_ivm = R8_interlace == 2'b11;
	wire [4:0] type0_seam_value = (type0_seam_ivm ? line_vma : line);
	wire [5:0] type0_seam_addend = (tog_line ? (tog_enter_line ? {5'b00000, parity_frame} : 6'd0) : (type0_seam_ivm ? {4'b0000, parity_c9 ^ R9_v_max_line[0]} : 6'd0));
	wire [5:0] type0_seam_target6 = {1'b0, type0_c0_r9} + type0_seam_addend;
	wire type0_c0_row_last = row == type0_c0_r4;
	wire type0_c0_line_last = (in_adj && !type0_r9_compare_active ? ((type0_add_line_active && (line == type0_c0_r5)) | (line == type0_c0_adjust_line_max)) | type0_c0_zero_adj_entry : {1'b0, type0_seam_value} == type0_seam_target6);
	assign c0_line_last = type0_c0_line_last;
	assign c0_row_last = type0_c0_row_last;
	wire type0_c1_toggle = tog_line || r8_toggle_write_t0;
	wire type0_c1_enter = (r8_toggle_write_t0 ? DI[1:0] == 2'b11 : tog_enter_line);
	wire [5:0] type0_c1_limit_addend = (type0_c1_toggle ? (type0_c1_enter ? {5'b00000, parity_frame} : 6'd0) : (ivm_disp_r ? {4'b0000, parity_c9 ^ type0_c0_r9[0]} : 6'd0));
	wire [5:0] type0_c1_limit_target = {1'b0, type0_c0_r9} + type0_c1_limit_addend;
	wire type0_c1_line_last = {1'b0, type0_limit_value} == type0_c1_limit_target;
	assign c1_last_line_validate = ((((!CRTC_TYPE && (hcc == 1)) && !in_adj) && !type0_c0_1_adjust_active) && type0_c1_line_last) && type0_c0_row_last;
	assign type0_r4_window_write = (((((!CRTC_TYPE && register_write) && (addr == 5'd4)) && (hcc >= 2)) && (hcc <= R0_h_total)) && type0_adjustment_selected) && !in_adj;
	assign type0_r4_switch_write = type0_r4_window_write && (DI[6:0] != row);
	assign type0_r9_compare_write = (((((!CRTC_TYPE && register_write) && (addr == 5'd9)) && (hcc >= 2)) && (hcc < R0_h_total)) && type0_adjustment_selected) && !in_adj;
	assign type0_r9_at_r0_write = (((((!CRTC_TYPE && register_write) && (addr == 5'd9)) && hcc_last) && (hcc >= 2)) && type0_adjustment_selected) && !in_adj;
	assign in_adj_route = ((!CRTC_TYPE && line_new) && !type0_adjust_end) && ((type0_r4_switch_active | type0_r9_compare_active) | type0_c0_1_adjust_active);
	assign frozen_row_advance = (((!CRTC_TYPE && r0_frozen) && !in_adj) && !type0_r0_zero_entry_consumed) && (line == R9_v_max_line);
	assign hcc2_adj_keep = |type0_effective_r5;
	assign reload = ~CRTC_TYPE & frame_new_w;
	assign row_addr_save = (hcc == R1_h_displayed) && type0_live_line_last;
	always @(posedge CLOCK)
		if ((~nRESET | SNA_LOAD) | CRTC_TYPE)
			type0_add_line_active <= 0;
		else if (CLKEN && type0_add_intercept)
			type0_add_line_active <= 1;
		else if (CLKEN && frame_new_w)
			type0_add_line_active <= 0;
	always @(posedge CLOCK)
		if ((~nRESET | SNA_LOAD) | CRTC_TYPE) begin
			type0_r4_adjust_switch <= 0;
			type0_r9_live_compare <= 0;
			type0_r9_at_r0_pending <= 0;
			type0_c0_1_adjust <= 0;
			type0_r0_zero_entry_consumed <= 0;
			type0_zero_adj_entry <= 0;
			type0_r5_adjust_override <= 0;
			type0_r5_adjust_target <= 0;
			type0_r0_widen_pending <= 0;
		end
		else begin
			if (type0_r0_widen_accept)
				type0_r0_widen_pending <= 1;
			else if (CLKEN && type0_r0_widen_pending)
				type0_r0_widen_pending <= 0;
			if (CLKEN && line_new)
				type0_r4_adjust_switch <= 0;
			else if (type0_r4_switch_write || type0_r9_pending_r4_cancel)
				type0_r4_adjust_switch <= 1;
			if (type0_r4_switch_active)
				type0_r9_live_compare <= 0;
			else if (((type0_c0_1_break_write && (addr == 5'd9)) && (row == R4_v_total)) || (type0_r9_compare_write && !type0_c0_1_adjust_active))
				type0_r9_live_compare <= 1;
			else if (CLKEN && row_new)
				type0_r9_live_compare <= 0;
			if (type0_r9_at_r0_write)
				type0_r9_at_r0_pending <= 1;
			else if (CLKEN && line_new)
				type0_r9_at_r0_pending <= 0;
			if (CLKEN && line_new) begin
				type0_r5_adjust_override <= 0;
				type0_r5_adjust_target <= 0;
			end
			else if (type0_c0_1_break_write && (addr == 5'd4)) begin
				type0_r5_adjust_override <= 1;
				type0_r5_adjust_target <= R5_v_total_adj - 5'd1;
			end
			else if (type0_r5_window_write) begin
				type0_r5_adjust_override <= 1;
				type0_r5_adjust_target <= DI[4:0] - 1'd1;
			end
			if (CLKEN && line_new)
				type0_c0_1_adjust <= 0;
			else if (type0_c0_1_break_write)
				type0_c0_1_adjust <= 1;
			if (!r0_frozen_w)
				type0_r0_zero_entry_consumed <= 0;
			else if (CLKEN)
				type0_r0_zero_entry_consumed <= 1;
			if ((type0_r5_write && (hcc <= 2)) && |DI[4:0])
				type0_zero_adj_entry <= 0;
			if (CLKEN) begin
				if (line_new && ((type0_r4_switch_active | type0_r9_compare_active) | type0_c0_1_adjust_active))
					type0_zero_adj_entry <= 0;
				else if ((((r0_frozen_w && !in_adj) && !type0_r0_zero_entry_consumed) && (line == R9_v_max_line)) && (row == R4_v_total))
					type0_zero_adj_entry <= !(|R5_v_total_adj);
				else if (row_new) begin
					if (frame_adj)
						type0_zero_adj_entry <= !(|type0_effective_r5);
					else if (frame_new_w)
						type0_zero_adj_entry <= 0;
				end
			end
		end
	reg type0_vsync_wait_line_start;
	reg type0_vsync_c0_2_seen;
	reg type0_vsync_preceding_c0_2;
	wire type0_vsync_line_reached_c0_2 = type0_vsync_c0_2_seen || (hcc >= 8'd2);
	wire type0_vsync_field_c0_2 = type0_vsync_preceding_c0_2 || type0_vsync_line_reached_c0_2;
	assign vsync_c0_2_qualified = (vsync_mid_phase ? type0_vsync_field_c0_2 : type0_vsync_line_reached_c0_2);
	always @(posedge CLOCK)
		if ((~nRESET | SNA_LOAD) | CRTC_TYPE) begin
			type0_vsync_c0_2_seen <= 0;
			type0_vsync_preceding_c0_2 <= 0;
		end
		else if (CLKEN) begin
			if (line_new) begin
				type0_vsync_preceding_c0_2 <= type0_vsync_line_reached_c0_2;
				type0_vsync_c0_2_seen <= 0;
			end
			else if (hcc == 8'd2)
				type0_vsync_c0_2_seen <= 1;
		end
	wire vsync_count_tick_t0 = CLKEN && (vsync_mid_phase ? !r0_frozen_w && (hcc_next == {1'b0, R0_h_total[7:1]}) : line_new);
	assign field_count_tick = !r0_frozen_w && (hcc_next == {1'b0, R0_h_total[7:1]});
	wire r7_write_hit = (((ENABLE & RS) & ~nCS) & ~R_nW) & (addr == 5'd7);
	wire r7_write_fire_t0 = (!VSYNC_r && vsync_allow) && (hcc > 1);
	assign r7_write_fire = r7_write_fire_t0;
	assign vsync_holdoff = !CRTC_TYPE && type0_vsync_wait_line_start;
	always @(posedge CLOCK)
		if (~nRESET)
			type0_vsync_wait_line_start <= 0;
		else begin
			if (vsync_count_tick_t0) begin
				if (!CRTC_TYPE && type0_vsync_wait_line_start)
					type0_vsync_wait_line_start <= 0;
			end
			if (r7_write_hit) begin
				if (row != DI[6:0])
					;
				else if (r7_write_fire_t0)
					type0_vsync_wait_line_start <= !vsync_count_tick_t0;
				else if (!VSYNC_r)
					type0_vsync_wait_line_start <= 0;
			end
			if (CRTC_TYPE || SNA_LOAD)
				type0_vsync_wait_line_start <= 0;
		end
	assign vde_toggle = ((!CRTC_TYPE && (row == 0)) && (line == 0)) && (R6_v_displayed == 0);
	wire vsync_fire_seam_raw = row_new && (row_next == R7_v_sync_pos);
	wire vsync_fire_seam = vsync_fire_seam_raw && type0_vsync_line_reached_c0_2;
	assign vsync_line_blocked = (vsync_mid_phase ? ((row == R7_v_sync_pos) && !line) && !type0_vsync_field_c0_2 : vsync_fire_seam_raw && !type0_vsync_line_reached_c0_2);
	wire type0_vsync_delay_arm = (((R9_v_max_line[0] && ivm_disp_r) && R7_v_sync_pos[0]) && parity_frame) && !in_adj;
	reg type0_vsync_delay_d1;
	reg type0_vsync_delay_d2;
	always @(posedge CLOCK)
		if ((~nRESET | SNA_LOAD) | CRTC_TYPE) begin
			type0_vsync_delay_d1 <= 0;
			type0_vsync_delay_d2 <= 0;
		end
		else if ((CLKEN && hcc_terminal) && !type0_r0_widen_accept) begin
			type0_vsync_delay_d1 <= vsync_fire_seam && type0_vsync_delay_arm;
			type0_vsync_delay_d2 <= type0_vsync_delay_d1;
		end
	assign vsync_line_fire = (vsync_fire_seam && !type0_vsync_delay_arm) || type0_vsync_delay_d1;
	assign vsync_delay_suppress = !CRTC_TYPE && type0_vsync_delay_d1;
	assign vsync_delay_half = !CRTC_TYPE && type0_vsync_delay_d2;
	assign vsc_load = R3_v_sync_width - 1'd1;
	assign hsync_off = hsc == R3_h_sync_width;
	assign de_index = R8_skew;
	assign spurious_border_off = (!CRTC_TYPE && (R1_h_displayed > R0_h_total)) && (hcc == R0_h_total);
	assign r6_vder_write = (row == DI[6:0]) && !((row == 0) && (line == 0));
	assign r6_vder_value = 1'b0;
endmodule
