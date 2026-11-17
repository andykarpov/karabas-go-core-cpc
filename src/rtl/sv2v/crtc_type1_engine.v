`default_nettype wire
module crtc_type1_engine (
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
	R4_v_total,
	R5_v_total_adj,
	R6_v_displayed,
	R7_v_sync_pos,
	R8_interlace,
	R9_v_max_line,
	hcc,
	hcc_next,
	hcc_last,
	hcc_end,
	line,
	row,
	c5,
	in_adj,
	crtc1_adj_from_row0,
	VSYNC_r,
	vsync_allow,
	hsc,
	vde_r,
	parity_frame,
	parity_c9,
	vsync_mid,
	line_last,
	line_new,
	line_next,
	c5_next,
	row_last,
	row_frame_last,
	row_next,
	row_new,
	frame_adj,
	adj_from_row0,
	reload,
	row0_reload,
	row_addr_save,
	field_count_tick,
	hsync_off,
	de_index,
	vsync_line_fire,
	vsc_load,
	r7_write_fire,
	r7_write_defer,
	r7_mid_fire,
	r6_vde_write,
	r6_vde_value,
	r6_vder_write,
	r6_vder_value,
	rfd_r0_extend,
	pf_write,
	pf_value,
	pc9_write,
	pc9_value,
	line_poke,
	line_poke_bit,
	status_bit5,
	r6_origin
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
	input [6:0] R4_v_total;
	input [4:0] R5_v_total_adj;
	input [6:0] R6_v_displayed;
	input [6:0] R7_v_sync_pos;
	input [1:0] R8_interlace;
	input [4:0] R9_v_max_line;
	input [7:0] hcc;
	input [7:0] hcc_next;
	input hcc_last;
	input hcc_end;
	input [4:0] line;
	input [6:0] row;
	input [4:0] c5;
	input in_adj;
	input crtc1_adj_from_row0;
	input VSYNC_r;
	input vsync_allow;
	input [3:0] hsc;
	input vde_r;
	input parity_frame;
	input parity_c9;
	input vsync_mid;
	output wire line_last;
	output wire line_new;
	output wire [4:0] line_next;
	output reg [4:0] c5_next;
	output wire row_last;
	output wire row_frame_last;
	output wire [6:0] row_next;
	output wire row_new;
	output wire frame_adj;
	output wire adj_from_row0;
	output wire reload;
	output wire row0_reload;
	output wire row_addr_save;
	output wire field_count_tick;
	output wire hsync_off;
	output wire [1:0] de_index;
	output wire vsync_line_fire;
	output wire [3:0] vsc_load;
	output wire r7_write_fire;
	output wire r7_write_defer;
	output wire r7_mid_fire;
	output wire r6_vde_write;
	output wire r6_vde_value;
	output wire r6_vder_write;
	output wire r6_vder_value;
	output wire rfd_r0_extend;
	output wire pf_write;
	output wire pf_value;
	output wire pc9_write;
	output wire pc9_value;
	output wire line_poke;
	output wire line_poke_bit;
	output wire status_bit5;
	output wire r6_origin;
	reg [1:0] tog_stage;
	reg tog_enter;
	reg ivm;
	wire r8_write_hit = ((((CRTC_TYPE & ENABLE) & RS) & ~nCS) & ~R_nW) & (addr == 5'd8);
	wire r8_toggle_write = r8_write_hit & ((DI[1:0] == 2'b11) != ivm);
	wire stage_a_edge = CLKEN && (tog_stage == 2'd1);
	wire stage_b_edge = CLKEN && (tog_stage == 2'd2);
	wire count_ivm = (stage_a_edge ? tog_enter : ivm);
	wire stage_a_x = row[0] & ~R9_v_max_line[0];
	wire stage_a_pc9 = line[0] ^ stage_a_x;
	wire stage_b_x = row[0] & ~R9_v_max_line[0];
	wire stage_b_pc9_value = (parity_frame ? parity_c9 : stage_b_x);
	wire stage_b_pf_value = parity_frame & (stage_b_pc9_value ^ stage_b_x);
	always @(posedge CLOCK)
		if (~nRESET | SNA_LOAD) begin
			tog_stage <= 2'd0;
			tog_enter <= 0;
			ivm <= 0;
		end
		else if (CRTC_TYPE) begin
			if (r8_toggle_write && (tog_stage == 2'd0)) begin
				tog_stage <= 2'd1;
				tog_enter <= DI[1:0] == 2'b11;
			end
			if (CLKEN) begin
				if (stage_a_edge) begin
					tog_stage <= 2'd2;
					ivm <= tog_enter;
				end
				else if (stage_b_edge)
					tog_stage <= 2'd0;
				else if (tog_stage == 2'd0)
					ivm <= R8_interlace == 2'b11;
			end
		end
		else begin
			tog_stage <= 2'd0;
			tog_enter <= 0;
			ivm <= 0;
		end
	wire [5:0] c9_pre = {1'b0, line} + (R9_v_max_line[0] ? 6'd0 : 6'd1);
	wire ivm_row_end = (c9_pre[4:0] & 5'b11110) == (R9_v_max_line & 5'b11110);
	wire [4:0] c9_ivm_step = (R9_v_max_line[0] ? c9_pre[4:0] + 5'd2 : c9_pre[4:0] + 5'd1);
	wire [4:0] pc9_toggled = {4'b0000, (R9_v_max_line[0] ? parity_c9 : ~parity_c9)};
	wire [4:0] crtc1_line_max = R9_v_max_line;
	wire r5_write_hit = ((((CRTC_TYPE & ENABLE) & RS) & ~nCS) & ~R_nW) & (addr == 5'd5);
	wire rfd_r5_accept = ((((nRESET && !SNA_LOAD) && hcc_last) && r5_write_hit) && (R5_v_total_adj == 0)) && |DI[4:0];
	reg rfd_r5_write_pending;
	wire rfd_arm = (((nRESET && !SNA_LOAD) && CRTC_TYPE) && CLKEN) && (rfd_r5_accept || rfd_r5_write_pending);
	wire [4:0] crtc1_rollover_r5 = (CLKEN && rfd_r5_accept ? DI[4:0] : R5_v_total_adj);
	always @(posedge CLOCK)
		if (((!nRESET || SNA_LOAD) || !CRTC_TYPE) || CLKEN)
			rfd_r5_write_pending <= 0;
		else if (rfd_r5_accept)
			rfd_r5_write_pending <= 1;
	wire [5:0] type1_r9p1 = {1'b0, R9_v_max_line} + 6'd1;
	wire type1_add_cond = |R5_v_total_adj && ((type1_r9p1 % {1'b0, R5_v_total_adj}) == 6'd0);
	wire type1_add_armed = R8_interlace[0] && !parity_frame;
	wire crtc1_adj_end = ((CRTC_TYPE & in_adj) & (({1'b0, c5} + 6'd1) == {1'b0, crtc1_rollover_r5})) & |crtc1_rollover_r5;
	reg type1_add_line_active;
	wire type1_add_intercept = ((line_new && type1_add_armed) && !type1_add_line_active) && (in_adj ? crtc1_adj_end : ((row == R4_v_total) && !(|crtc1_rollover_r5)) && (count_ivm ? ivm_row_end : line == crtc1_line_max));
	wire crtc1_adj_end_eff = crtc1_adj_end || (type1_add_line_active && line_new);
	wire line_last_w = line == crtc1_line_max;
	wire ordinary_row_last = (count_ivm ? ivm_row_end : line_last_w);
	wire adj_terminal_write_accept = ((((((((((((nRESET && !SNA_LOAD) && CRTC_TYPE) && hcc_last) && !in_adj) && !type1_add_line_active) && (row == R4_v_total)) && ordinary_row_last) && |R5_v_total_adj) && ENABLE) && RS) && !nCS) && !R_nW) && ((addr == 5'd4) || (addr == 5'd9));
	wire adj_terminal_positive_r4 = (adj_terminal_write_accept && (addr == 5'd4)) && |DI[6:0];
	reg adj_terminal_write_pending;
	reg adj_terminal_positive_r4_pending;
	always @(posedge CLOCK)
		if (((!nRESET || SNA_LOAD) || !CRTC_TYPE) || CLKEN) begin
			adj_terminal_write_pending <= 0;
			adj_terminal_positive_r4_pending <= 0;
		end
		else if (adj_terminal_write_accept) begin
			adj_terminal_write_pending <= 1;
			adj_terminal_positive_r4_pending <= adj_terminal_positive_r4;
		end
	wire adj_terminal_entry = hcc_end && (adj_terminal_write_accept || adj_terminal_write_pending);
	wire line_limit_match = (type1_add_line_active ? 1'b1 : (in_adj ? crtc1_adj_end_eff : ordinary_row_last));
	wire type1_adj_counter_end = crtc1_adj_end_eff && (!type1_add_intercept || type1_add_cond);
	wire line_row_event = (type1_add_line_active ? 1'b1 : (in_adj ? ordinary_row_last | type1_adj_counter_end : ordinary_row_last));
	wire line_row_structure_last = (in_adj ? ordinary_row_last : line_limit_match);
	assign line_last = line_limit_match;
	assign line_new = hcc_end;
	wire r0_write_hit = ((((CRTC_TYPE & ENABLE) & RS) & ~nCS) & ~R_nW) & (addr == 5'd0);
	wire rfd_r0_write_accept = (((((((nRESET & ~SNA_LOAD) & hcc_last) & r0_write_hit) & ({1'b0, DI} > {1'b0, R0_h_total})) & (line == crtc1_line_max)) & (row == R4_v_total)) & (R5_v_total_adj == 0)) & ~in_adj;
	reg rfd_r0_write_pending;
	wire rfd_r0_widen_at_last_line = (((nRESET && !SNA_LOAD) && CRTC_TYPE) && CLKEN) && (rfd_r0_write_accept || rfd_r0_write_pending);
	always @(posedge CLOCK)
		if (((!nRESET || SNA_LOAD) || !CRTC_TYPE) || CLKEN)
			rfd_r0_write_pending <= 0;
		else if (rfd_r0_write_accept)
			rfd_r0_write_pending <= 1;
	assign rfd_r0_extend = rfd_r0_widen_at_last_line;
	wire rfd_r0_cancelled = (line != crtc1_line_max) | ((row != R4_v_total) & ~parity_frame);
	reg rfd_r0_pending;
	wire rfd_r0_arm = ((rfd_r0_pending & CLKEN) & hcc_end) & rfd_r0_cancelled;
	always @(*)
		if (line_new) begin
			if (in_adj) begin
				if (crtc1_adj_end_eff)
					c5_next = 5'd0;
				else if ((((row == R4_v_total) && ordinary_row_last) && |crtc1_rollover_r5) && !type1_add_line_active)
					c5_next = 5'd0;
				else
					c5_next = c5 + 1'd1;
			end
			else
				c5_next = 5'd0;
		end
		else
			c5_next = c5;
	wire row_last_w = row == R4_v_total;
	assign row_last = row_last_w;
	wire frame_adj_CRTC1 = ((((row_last_w && ordinary_row_last) || adj_terminal_entry) && ~in_adj) && !type1_add_line_active) && |crtc1_rollover_r5;
	assign frame_adj = frame_adj_CRTC1;
	wire crtc1_stuck_r5_row_reset = ((in_adj && !(|crtc1_rollover_r5)) && row_last_w) && ordinary_row_last;
	wire crtc1_stuck_r5_row_reset_event = crtc1_stuck_r5_row_reset && line_new;
	wire crtc1_row_frame_last = type1_add_line_active || (!type1_add_intercept && (in_adj ? crtc1_adj_end_eff : row_last_w & ~frame_adj_CRTC1));
	assign row_frame_last = crtc1_row_frame_last;
	assign row_next = (row_frame_last | crtc1_stuck_r5_row_reset ? 7'd0 : row + 1'd1);
	assign row_new = line_new & line_row_event;
	wire frame_new_w = row_new & row_frame_last;
	assign r6_origin = frame_new_w | crtc1_stuck_r5_row_reset_event;
	assign line_next = (frame_new_w ? (count_ivm ? {4'b0000, ~parity_frame} : 5'd0) : (in_adj && type1_adj_counter_end ? 5'd0 : (count_ivm ? (ordinary_row_last ? pc9_toggled : c9_ivm_step) : (ordinary_row_last ? 5'd0 : line + 5'd1))));
	always @(posedge CLOCK)
		if ((~nRESET | SNA_LOAD) | !CRTC_TYPE)
			type1_add_line_active <= 0;
		else if (CLKEN && type1_add_intercept)
			type1_add_line_active <= 1;
		else if (CLKEN && frame_new_w)
			type1_add_line_active <= 0;
	wire c4_increment_toggle = row_new && !R9_v_max_line[0];
	assign pc9_write = ((stage_a_edge || (stage_b_edge && tog_enter)) || frame_new_w) || c4_increment_toggle;
	assign pc9_value = (stage_a_edge ? stage_a_pc9 : (stage_b_edge && tog_enter ? stage_b_pc9_value : (frame_new_w ? ~parity_frame : ~parity_c9)));
	assign pf_write = stage_b_edge || frame_new_w;
	assign pf_value = (stage_b_edge ? (tog_enter ? stage_b_pf_value : parity_c9) : ~parity_frame);
	assign line_poke = stage_a_edge || stage_b_edge;
	assign line_poke_bit = (stage_a_edge ? stage_a_pc9 : (tog_enter ? stage_b_pc9_value : parity_c9));
	reg rfd_vma_flag;
	reg rfd_parity_flag;
	wire rfd_vma_disarm_hit = rfd_arm & (line == crtc1_line_max);
	wire rfd_vma_arm = (rfd_arm & (line != crtc1_line_max)) | rfd_r0_arm;
	wire rfd_parity_active = (rfd_parity_flag | rfd_arm) | rfd_r0_arm;
	wire rfd_vma_active = (rfd_vma_flag & ~rfd_vma_disarm_hit) | rfd_vma_arm;
	wire rfd_r1_gt_r0_disarm = (rfd_vma_flag & (R1_h_displayed > R0_h_total)) & line_last_w;
	wire r4_positive_write_at_adj_entry = (((((((CRTC_TYPE & CLKEN) & hcc_last) & ENABLE) & RS) & ~nCS) & ~R_nW) & (addr == 5'd4)) & |DI[6:0];
	wire crtc1_adj_entry_from_row0 = (((CRTC_TYPE & frame_adj_CRTC1) & (row == 0)) & ~r4_positive_write_at_adj_entry) & ~(adj_terminal_entry & adj_terminal_positive_r4_pending);
	assign adj_from_row0 = crtc1_adj_entry_from_row0;
	wire crtc1_adj_row1_reload = (CRTC_TYPE & (crtc1_adj_entry_from_row0 | ((in_adj & crtc1_adj_from_row0) & (((row == 1) & ~line_row_structure_last) | ((row_new & (row == 0)) & (row_next == 7'd1)))))) & !hcc_next;
	wire crtc1_row0_reload = CRTC_TYPE & ((frame_new_w | crtc1_stuck_r5_row_reset_event) | ((~line_row_structure_last & !row) & !hcc_next));
	wire crtc1_rfd_reload = (CRTC_TYPE & rfd_vma_active) & !hcc_next;
	assign reload = (crtc1_row0_reload | crtc1_adj_row1_reload) | crtc1_rfd_reload;
	assign row0_reload = crtc1_row0_reload;
	wire row_addr_save_base = (hcc == R1_h_displayed) && line_row_structure_last;
	assign row_addr_save = row_addr_save_base & (~rfd_parity_active | parity_frame);
	always @(posedge CLOCK)
		if (~nRESET | SNA_LOAD) begin
			rfd_vma_flag <= 0;
			rfd_parity_flag <= 0;
			rfd_r0_pending <= 0;
		end
		else if (CRTC_TYPE) begin
			if (((CLKEN && row_addr_save) | rfd_r1_gt_r0_disarm) | (rfd_arm & (line == crtc1_line_max)))
				rfd_vma_flag <= 0;
			else if (rfd_vma_arm)
				rfd_vma_flag <= 1;
			if (rfd_arm | rfd_r0_arm)
				rfd_parity_flag <= 1;
			else if (CLKEN && (frame_new_w || row_addr_save))
				rfd_parity_flag <= 0;
			if (CLKEN) begin
				if (rfd_r0_widen_at_last_line)
					rfd_r0_pending <= 1;
				else if (hcc_end)
					rfd_r0_pending <= 0;
			end
		end
		else begin
			rfd_vma_flag <= 0;
			rfd_parity_flag <= 0;
			rfd_r0_pending <= 0;
		end
	assign field_count_tick = hcc_next == {1'b0, R0_h_total[7:1]};
	assign vsync_line_fire = ((((CRTC_TYPE && in_adj) && !crtc1_adj_end) && !crtc1_stuck_r5_row_reset ? row + 1'd1 : row_next) == R7_v_sync_pos) && line_row_structure_last;
	assign vsc_load = 4'd0 - 1'd1;
	assign r7_write_fire = !VSYNC_r && vsync_allow;
	reg type1_r7_mid_pending;
	wire r7_write_hit = (((ENABLE && RS) && !nCS) && !R_nW) && (addr == 5'd7);
	wire type1_r7_mid_now = CLKEN && field_count_tick;
	assign r7_write_defer = (((CRTC_TYPE && R8_interlace[0]) && vsync_mid) && (hcc < {1'b0, R0_h_total[7:1]})) && !type1_r7_mid_now;
	always @(posedge CLOCK)
		if ((!nRESET || SNA_LOAD) || !CRTC_TYPE)
			type1_r7_mid_pending <= 0;
		else begin
			if (CLKEN && (line_new || (vsync_mid && field_count_tick)))
				type1_r7_mid_pending <= 0;
			if (((r7_write_hit && (row == DI[6:0])) && r7_write_fire) && r7_write_defer)
				type1_r7_mid_pending <= 1;
		end
	assign r7_mid_fire = (((CRTC_TYPE && R8_interlace[0]) && vsync_mid) && type1_r7_mid_pending) && !VSYNC_r;
	assign hsync_off = (hsc == R3_h_sync_width) || (R3_h_sync_width == 0);
	assign de_index = 2'b00;
	wire r6w_a = (row != DI[6:0]) && (DI[6:0] != 0);
	wire r6w_b = (row == R6_v_displayed) && (DI[6:0] != row);
	wire r6w_c = (row == DI[6:0]) || (DI[6:0] == 0);
	assign r6_vder_write = row == DI[6:0];
	assign r6_vder_value = 1'b0;
	assign r6_vde_write = (r6w_a | r6w_b) | r6w_c;
	assign r6_vde_value = (r6w_c ? 1'b0 : (r6w_b ? 1'b1 : vde_r));
	reg r6_border_condition;
	reg status_bit5_r;
	always @(posedge CLOCK)
		if (~nRESET | SNA_LOAD) begin
			r6_border_condition <= 0;
			status_bit5_r <= 0;
		end
		else if (CRTC_TYPE) begin
			if (CLKEN && row_new) begin
				if (r6_origin)
					r6_border_condition <= 0;
				else if (row_next == R6_v_displayed)
					r6_border_condition <= 1;
			end
			if ((((((nCLKEN & ENABLE) & RS) & ~nCS) & ~R_nW) & (addr == 5'd6)) & (row == DI[6:0]))
				r6_border_condition <= 1;
			if (CLKEN && hcc_end) begin
				if (r6_origin)
					status_bit5_r <= 0;
				else if (row_new && (row_next == R6_v_displayed))
					status_bit5_r <= 1;
				else
					status_bit5_r <= r6_border_condition;
			end
		end
		else begin
			r6_border_condition <= 0;
			status_bit5_r <= 0;
		end
	assign status_bit5 = status_bit5_r;
endmodule
