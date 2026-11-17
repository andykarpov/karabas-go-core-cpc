`default_nettype wire
module asic_regs (
	clk,
	reset,
	asic_cs,
	mem_wr,
	mem_rd,
	A,
	D_in,
	D_out,
	read_driven,
	leg_pal_wr,
	leg_pal_addr,
	leg_pal_data,
	leg_border,
	leg_inkr,
	pal_raddr,
	pal_rdata,
	pri,
	splt,
	sscr,
	ivr,
	ssa_hi,
	ssa_lo,
	dcsr,
	intack_raster,
	intack,
	intack_m1,
	int_pending,
	vec_byte,
	vec_valid,
	dma_int_set,
	sprq_req,
	sprq_addr,
	sprq_data,
	sprq_ack,
	spr_acc_en,
	spr_acc_idx,
	spr_wr_en,
	spr_wr_addr,
	spr_wr_data,
	spr_x_view,
	spr_y_view,
	spr_mag_view,
	spr_pal_view,
	sar0_lo,
	sar0_hi,
	ppr0,
	sar0_wr,
	sar1_lo,
	sar1_hi,
	ppr1,
	sar1_wr,
	sar2_lo,
	sar2_hi,
	ppr2,
	sar2_wr,
	ppr0_wr,
	ppr1_wr,
	ppr2_wr,
	dcsr_ena_out,
	dcsr_ena_clr,
	dma_int_req,
	sna_wr,
	sna_addr,
	sna_data,
	sna_pal_load,
	sna_pal_plain,
	sna_pal_hdr
);
	input clk;
	input reset;
	input asic_cs;
	input mem_wr;
	input mem_rd;
	input [13:0] A;
	input [7:0] D_in;
	output wire [7:0] D_out;
	output wire read_driven;
	input leg_pal_wr;
	input [4:0] leg_pal_addr;
	input [4:0] leg_pal_data;
	input [4:0] leg_border;
	input [79:0] leg_inkr;
	input [4:0] pal_raddr;
	output wire [11:0] pal_rdata;
	output wire [7:0] pri;
	output wire [7:0] splt;
	output wire [7:0] sscr;
	output wire [7:0] ivr;
	output wire [7:0] ssa_hi;
	output wire [7:0] ssa_lo;
	output wire [7:0] dcsr;
	input intack_raster;
	input intack;
	input intack_m1;
	input int_pending;
	output wire [7:0] vec_byte;
	output wire vec_valid;
	input [2:0] dma_int_set;
	input sprq_req;
	input [10:0] sprq_addr;
	output wire [7:0] sprq_data;
	output reg sprq_ack;
	output wire spr_acc_en;
	output wire [3:0] spr_acc_idx;
	output wire spr_wr_en;
	output wire [11:0] spr_wr_addr;
	output wire [3:0] spr_wr_data;
	output wire [159:0] spr_x_view;
	output wire [143:0] spr_y_view;
	output wire [63:0] spr_mag_view;
	output wire [179:0] spr_pal_view;
	output wire [7:0] sar0_lo;
	output wire [7:0] sar0_hi;
	output wire [7:0] ppr0;
	output wire sar0_wr;
	output wire [7:0] sar1_lo;
	output wire [7:0] sar1_hi;
	output wire [7:0] ppr1;
	output wire sar1_wr;
	output wire [7:0] sar2_lo;
	output wire [7:0] sar2_hi;
	output wire [7:0] ppr2;
	output wire sar2_wr;
	output wire ppr0_wr;
	output wire ppr1_wr;
	output wire ppr2_wr;
	output wire [2:0] dcsr_ena_out;
	input [2:0] dcsr_ena_clr;
	output wire dma_int_req;
	input sna_wr;
	input [13:0] sna_addr;
	input [7:0] sna_data;
	input sna_pal_load;
	input sna_pal_plain;
	input [135:0] sna_pal_hdr;
	wire [3:0] spr_host_rdata;
	wire [7:0] spr_video_rdata;
	reg [7:0] spr_x_lo [0:15];
	reg [1:0] spr_x_hi [0:15];
	reg [7:0] spr_y_lo [0:15];
	reg spr_y_hi [0:15];
	reg [7:0] spr_mag [0:15];
	reg [11:0] pal [0:31];
	reg [11:0] pal_r;
	reg [7:0] pri_r;
	reg [7:0] splt_r;
	reg [7:0] sscr_r;
	reg [7:0] ivr_r;
	reg [7:0] ssa_hi_r;
	reg [7:0] ssa_lo_r;
	reg dcsr_stat;
	reg intack_d;
	reg [2:0] dcsr_flags;
	reg [2:0] dcsr_ena;
	reg [7:0] sar_lo [0:2];
	reg [7:0] sar_hi [0:2];
	reg [7:0] ppr [0:2];
	assign pri = pri_r;
	assign splt = splt_r;
	assign sscr = sscr_r;
	assign ivr = ivr_r;
	assign ssa_hi = ssa_hi_r;
	assign ssa_lo = ssa_lo_r;
	assign dcsr = {dcsr_stat | intack_raster, dcsr_flags[0], dcsr_flags[1], dcsr_flags[2], 1'b0, dcsr_ena};
	wire eff_cs = (asic_cs && mem_wr) || sna_wr;
	wire [13:0] eff_addr = (sna_wr ? sna_addr : A[13:0]);
	wire [7:0] eff_data = (sna_wr ? sna_data : D_in);
	wire [1:0] eff_wsel = eff_addr[13:12];
	assign sar0_wr = (((!reset && eff_cs) && (eff_wsel == 2'b10)) && (eff_addr[11:4] == 8'hc0)) && ((eff_addr[3:0] == 4'h0) || (eff_addr[3:0] == 4'h1));
	assign sar1_wr = (((!reset && eff_cs) && (eff_wsel == 2'b10)) && (eff_addr[11:4] == 8'hc0)) && ((eff_addr[3:0] == 4'h4) || (eff_addr[3:0] == 4'h5));
	assign sar2_wr = (((!reset && eff_cs) && (eff_wsel == 2'b10)) && (eff_addr[11:4] == 8'hc0)) && ((eff_addr[3:0] == 4'h8) || (eff_addr[3:0] == 4'h9));
	wire [1:0] wsel = A[13:12];
	wire ppr0_dec = (((((!reset && asic_cs) && mem_wr) && !sna_wr) && (wsel == 2'b10)) && (A[11:4] == 8'hc0)) && (A[3:0] == 4'h2);
	wire ppr1_dec = (((((!reset && asic_cs) && mem_wr) && !sna_wr) && (wsel == 2'b10)) && (A[11:4] == 8'hc0)) && (A[3:0] == 4'h6);
	wire ppr2_dec = (((((!reset && asic_cs) && mem_wr) && !sna_wr) && (wsel == 2'b10)) && (A[11:4] == 8'hc0)) && (A[3:0] == 4'ha);
	reg ppr0_dec_q;
	reg ppr1_dec_q;
	reg ppr2_dec_q;
	reg ppr0_wr_r;
	reg ppr1_wr_r;
	reg ppr2_wr_r;
	assign ppr0_wr = ppr0_wr_r;
	assign ppr1_wr = ppr1_wr_r;
	assign ppr2_wr = ppr2_wr_r;
	wire [7:0] next_sar0_lo = (sar0_wr && (eff_addr[3:0] == 4'h0) ? eff_data : sar_lo[0]);
	wire [7:0] next_sar0_hi = (sar0_wr && (eff_addr[3:0] == 4'h1) ? eff_data : sar_hi[0]);
	wire [7:0] next_sar1_lo = (sar1_wr && (eff_addr[3:0] == 4'h4) ? eff_data : sar_lo[1]);
	wire [7:0] next_sar1_hi = (sar1_wr && (eff_addr[3:0] == 4'h5) ? eff_data : sar_hi[1]);
	wire [7:0] next_sar2_lo = (sar2_wr && (eff_addr[3:0] == 4'h8) ? eff_data : sar_lo[2]);
	wire [7:0] next_sar2_hi = (sar2_wr && (eff_addr[3:0] == 4'h9) ? eff_data : sar_hi[2]);
	assign sar0_lo = next_sar0_lo;
	assign sar0_hi = next_sar0_hi;
	assign ppr0 = ppr[0];
	assign sar1_lo = next_sar1_lo;
	assign sar1_hi = next_sar1_hi;
	assign ppr1 = ppr[1];
	assign sar2_lo = next_sar2_lo;
	assign sar2_hi = next_sar2_hi;
	assign ppr2 = ppr[2];
	assign dcsr_ena_out = dcsr_ena;
	assign dma_int_req = |dcsr_flags;
	function [11:0] legacy_colour_gbr;
		input [4:0] hw;
		case (hw)
			5'd0: legacy_colour_gbr = 12'h666;
			5'd1: legacy_colour_gbr = 12'h666;
			5'd2: legacy_colour_gbr = 12'hf06;
			5'd3: legacy_colour_gbr = 12'hff6;
			5'd4: legacy_colour_gbr = 12'h006;
			5'd5: legacy_colour_gbr = 12'h0f6;
			5'd6: legacy_colour_gbr = 12'h606;
			5'd7: legacy_colour_gbr = 12'h6f6;
			5'd8: legacy_colour_gbr = 12'h0f6;
			5'd9: legacy_colour_gbr = 12'hff6;
			5'd10: legacy_colour_gbr = 12'hff0;
			5'd11: legacy_colour_gbr = 12'hfff;
			5'd12: legacy_colour_gbr = 12'h0f0;
			5'd13: legacy_colour_gbr = 12'hff0;
			5'd14: legacy_colour_gbr = 12'h6f0;
			5'd15: legacy_colour_gbr = 12'h6ff;
			5'd16: legacy_colour_gbr = 12'h006;
			5'd17: legacy_colour_gbr = 12'hf06;
			5'd18: legacy_colour_gbr = 12'hf00;
			5'd19: legacy_colour_gbr = 12'hf0f;
			5'd20: legacy_colour_gbr = 12'h000;
			5'd21: legacy_colour_gbr = 12'h00f;
			5'd22: legacy_colour_gbr = 12'h600;
			5'd23: legacy_colour_gbr = 12'h60f;
			5'd24: legacy_colour_gbr = 12'h066;
			5'd25: legacy_colour_gbr = 12'hf66;
			5'd26: legacy_colour_gbr = 12'hf60;
			5'd27: legacy_colour_gbr = 12'hf6f;
			5'd28: legacy_colour_gbr = 12'h060;
			5'd29: legacy_colour_gbr = 12'h06f;
			5'd30: legacy_colour_gbr = 12'h660;
			5'd31: legacy_colour_gbr = 12'h66f;
			default: legacy_colour_gbr = 12'h000;
		endcase
	endfunction
	reg [79:0] leg_inkr_q;
	reg [4:0] leg_border_q;
	reg import_pending;
	integer k;
	wire r_sprreg = (wsel == 2'b10) && (A[11:7] == 5'd0);
	wire r_pal = (wsel == 2'b10) && (A[11:6] == 6'h10);
	wire r_raster = (wsel == 2'b10) && (A[11:4] == 8'h80);
	wire r_dma = (wsel == 2'b10) && (A[11:4] == 8'hc0);
	wire eff_r_sprreg = (eff_wsel == 2'b10) && (eff_addr[11:7] == 5'd0);
	wire eff_r_pal = (eff_wsel == 2'b10) && (eff_addr[11:6] == 6'h10);
	wire eff_r_raster = (eff_wsel == 2'b10) && (eff_addr[11:4] == 8'h80);
	wire eff_r_dma = (eff_wsel == 2'b10) && (eff_addr[11:4] == 8'hc0);
	wire dcsr_w1c_hit = (((((!reset && asic_cs) && mem_wr) && !sna_wr) && (wsel == 2'b10)) && (A[11:4] == 8'hc0)) && (A[3:0] == 4'hf);
	wire dcsr_sna_hit = (((!reset && sna_wr) && (sna_addr[13:12] == 2'b10)) && (sna_addr[11:4] == 8'hc0)) && (sna_addr[3:0] == 4'hf);
	wire [2:0] dcsr_w1c_mask = {D_in[4], D_in[5], D_in[6]};
	wire auto_clr_dma = ((intack && !intack_d) && !ivr_r[0]) && !int_pending;
	wire [2:0] auto_clr_mask = (dcsr_flags[2] ? 3'b100 : (dcsr_flags[1] ? 3'b010 : (dcsr_flags[0] ? 3'b001 : 3'b000)));
	wire [4:0] pal_idx = A[5:1];
	wire [4:0] eff_pal_idx = eff_addr[5:1];
	always @(posedge clk) begin
		if (reset) begin
			pri_r <= 8'd0;
			splt_r <= 8'd0;
			sscr_r <= 8'd0;
			ivr_r <= 8'b00000001;
			ssa_hi_r <= 8'd0;
			ssa_lo_r <= 8'd0;
			dcsr_stat <= 1'b0;
			dcsr_flags <= 3'd0;
			dcsr_ena <= 3'd0;
			sar_lo[0] <= 8'd0;
			sar_hi[0] <= 8'd0;
			ppr[0] <= 8'd0;
			sar_lo[1] <= 8'd0;
			sar_hi[1] <= 8'd0;
			ppr[1] <= 8'd0;
			sar_lo[2] <= 8'd0;
			sar_hi[2] <= 8'd0;
			ppr[2] <= 8'd0;
			ppr0_dec_q <= 1'b0;
			ppr1_dec_q <= 1'b0;
			ppr2_dec_q <= 1'b0;
			ppr0_wr_r <= 1'b0;
			ppr1_wr_r <= 1'b0;
			ppr2_wr_r <= 1'b0;
			for (k = 0; k < 16; k = k + 1)
				begin
					spr_x_lo[k] <= 8'd0;
					spr_x_hi[k] <= 2'd0;
					spr_y_lo[k] <= 8'd0;
					spr_y_hi[k] <= 1'b0;
					spr_mag[k] <= 8'd0;
				end
			for (k = 0; k < 32; k = k + 1)
				pal[k] <= 12'd0;
			leg_inkr_q <= {80 {1'b1}};
			leg_border_q <= 5'b11111;
			import_pending <= 1'b1;
		end
		if (!reset) begin
			if (dcsr_sna_hit) begin
				dcsr_flags <= {sna_data[4], sna_data[5], sna_data[6]};
				dcsr_ena <= sna_data[2:0];
				dcsr_stat <= sna_data[7];
			end
			else begin
				if (intack && !intack_d)
					dcsr_stat <= 1'b0;
				dcsr_flags <= ((dcsr_flags | dma_int_set) & (dcsr_w1c_hit ? ~dcsr_w1c_mask : 3'b111)) & (auto_clr_dma ? ~auto_clr_mask : 3'b111);
				if (dcsr_w1c_hit)
					dcsr_ena <= D_in[2:0] & ~dcsr_ena_clr;
				else
					dcsr_ena <= dcsr_ena & ~dcsr_ena_clr;
			end
		end
		if (!reset) begin
			ppr0_dec_q <= ppr0_dec;
			ppr1_dec_q <= ppr1_dec;
			ppr2_dec_q <= ppr2_dec;
			ppr0_wr_r <= ppr0_dec && !ppr0_dec_q;
			ppr1_wr_r <= ppr1_dec && !ppr1_dec_q;
			ppr2_wr_r <= ppr2_dec && !ppr2_dec_q;
		end
		if (!reset && eff_cs) begin
			if (eff_wsel == 2'b10) begin
				if (eff_r_sprreg)
					case (eff_addr[2:0])
						3'd0: spr_x_lo[eff_addr[6:3]] <= eff_data;
						3'd1: spr_x_hi[eff_addr[6:3]] <= eff_data[1:0];
						3'd2: spr_y_lo[eff_addr[6:3]] <= eff_data;
						3'd3: spr_y_hi[eff_addr[6:3]] <= eff_data[0];
						default: spr_mag[eff_addr[6:3]] <= eff_data;
					endcase
				else if (eff_r_pal) begin
					if (!eff_addr[0])
						pal[eff_pal_idx] <= {pal[eff_pal_idx][11:8], eff_data[7:4], eff_data[3:0]};
					else
						pal[eff_pal_idx] <= {eff_data[3:0], pal[eff_pal_idx][7:4], pal[eff_pal_idx][3:0]};
				end
				else if (eff_r_raster)
					case (eff_addr[3:0])
						4'h0: pri_r <= eff_data;
						4'h1: splt_r <= eff_data;
						4'h2: ssa_hi_r <= eff_data;
						4'h3: ssa_lo_r <= eff_data;
						4'h4: sscr_r <= eff_data;
						4'h5: ivr_r <= eff_data;
						default:
							;
					endcase
				else if (eff_r_dma)
					case (eff_addr[3:0])
						4'h0: sar_lo[0] <= eff_data;
						4'h1: sar_hi[0] <= eff_data;
						4'h2: ppr[0] <= eff_data;
						4'h4: sar_lo[1] <= eff_data;
						4'h5: sar_hi[1] <= eff_data;
						4'h6: ppr[1] <= eff_data;
						4'h8: sar_lo[2] <= eff_data;
						4'h9: sar_hi[2] <= eff_data;
						4'ha: ppr[2] <= eff_data;
						4'hf:
							;
						default:
							;
					endcase
			end
		end
		if (!reset && import_pending) begin
			for (k = 0; k < 16; k = k + 1)
				if (leg_inkr[k * 5+:5] != leg_inkr_q[k * 5+:5])
					pal[k] <= legacy_colour_gbr(leg_inkr[k * 5+:5]);
			if (leg_border != leg_border_q)
				pal[16] <= legacy_colour_gbr(leg_border);
			leg_inkr_q <= leg_inkr;
			leg_border_q <= leg_border;
			import_pending <= 1'b0;
		end
		if ((!reset && leg_pal_wr) && (leg_pal_addr <= 5'd16))
			pal[leg_pal_addr] <= legacy_colour_gbr(leg_pal_data);
		if ((!reset && sna_pal_load) && sna_pal_plain)
			for (k = 0; k < 17; k = k + 1)
				pal[k] <= legacy_colour_gbr(sna_pal_hdr[k * 8+:5]);
	end
	reg [7:0] rdata;
	reg renable;
	function [7:0] xhi_read;
		input [1:0] v;
		xhi_read = (v == 2'b11 ? 8'hff : {6'd0, v});
	endfunction
	function [7:0] yhi_read;
		input v;
		yhi_read = (v ? 8'hff : 8'd0);
	endfunction
	always @(*) begin
		rdata = 8'hff;
		renable = 1'b0;
		if (asic_cs && mem_rd) begin
			if (wsel == 2'b00) begin
				rdata = {4'h0, spr_host_rdata};
				renable = 1'b1;
			end
			else if (wsel == 2'b10) begin
				if (r_sprreg)
					case (A[2:0])
						3'd0, 3'd4: begin
							rdata = spr_x_lo[A[6:3]];
							renable = 1'b1;
						end
						3'd1, 3'd5: begin
							rdata = xhi_read(spr_x_hi[A[6:3]]);
							renable = 1'b1;
						end
						3'd2, 3'd6: begin
							rdata = spr_y_lo[A[6:3]];
							renable = 1'b1;
						end
						3'd3, 3'd7: begin
							rdata = yhi_read(spr_y_hi[A[6:3]]);
							renable = 1'b1;
						end
					endcase
				else if (r_pal) begin
					rdata = (A[0] ? {4'h0, pal[pal_idx][11:8]} : {pal[pal_idx][7:4], pal[pal_idx][3:0]});
					renable = 1'b1;
				end
				else if (r_dma) begin
					rdata = {dcsr_stat | intack_raster, dcsr_flags[0], dcsr_flags[1], dcsr_flags[2], 1'b0, dcsr_ena};
					renable = 1'b1;
				end
				else if (r_raster && A[3])
					case (A[2:0])
						3'h0: begin
							rdata = 8'h3f;
							renable = 1'b1;
						end
						3'h1: begin
							rdata = 8'h3f;
							renable = 1'b1;
						end
						3'h2: begin
							rdata = 8'h3f;
							renable = 1'b1;
						end
						3'h3: begin
							rdata = 8'h3f;
							renable = 1'b1;
						end
						3'h4: begin
							rdata = 8'h3f;
							renable = 1'b1;
						end
						3'h5: begin
							rdata = 8'h00;
							renable = 1'b1;
						end
						3'h6: begin
							rdata = 8'h3f;
							renable = 1'b1;
						end
						3'h7: begin
							rdata = 8'h00;
							renable = 1'b1;
						end
					endcase
			end
		end
	end
	assign D_out = rdata | {8 {~renable}};
	assign read_driven = renable;
	assign pal_rdata = pal_r;
	reg ack_seen;
	reg [2:0] ack_src;
	always @(posedge clk)
		if (reset) begin
			intack_d <= 1'b0;
			ack_src <= 3'd0;
			ack_seen <= 1'b0;
		end
		else begin
			intack_d <= intack;
			if (!intack_m1)
				ack_seen <= 1'b0;
			if (intack && !intack_d) begin
				ack_seen <= 1'b1;
				if (int_pending)
					ack_src <= 3'b110;
				else if (dcsr_flags[2])
					ack_src <= 3'b000;
				else if (dcsr_flags[1])
					ack_src <= 3'b010;
				else if (dcsr_flags[0])
					ack_src <= 3'b100;
				else
					ack_src <= (ack_seen && intack_m1 ? 3'b100 : 3'b000);
			end
		end
	wire [7:0] vec_src = ivr_r & 8'hf8;
	assign vec_byte = vec_src | {5'd0, ack_src};
	assign vec_valid = intack;
	always @(posedge clk)
		if (reset)
			pal_r <= 12'd0;
		else
			pal_r <= pal[pal_raddr];
	wire sprq_grant = sprq_req && !(asic_cs && mem_rd);
	wire spr_host_wr = (!reset && eff_cs) && (eff_wsel == 2'b00);
	wire spr_host_rd = (asic_cs && mem_rd) && (wsel == 2'b00);
	plus_sprite_ram spr_ram_inst(
		.clk(clk),
		.reset(reset),
		.host_rd(spr_host_rd),
		.host_wr(spr_host_wr),
		.host_addr(eff_addr[11:0]),
		.host_wdata(eff_data[3:0]),
		.host_rdata(spr_host_rdata),
		.video_rd(sprq_req),
		.video_addr(sprq_addr),
		.video_rdata(spr_video_rdata)
	);
	assign sprq_data = spr_video_rdata;
	always @(posedge clk)
		if (reset)
			sprq_ack <= 1'b0;
		else
			sprq_ack <= sprq_grant;
	assign spr_acc_en = (asic_cs && (mem_rd || mem_wr)) && (wsel == 2'b00);
	assign spr_acc_idx = A[11:8];
	assign spr_wr_en = ((asic_cs && mem_wr) && (wsel == 2'b00)) || (sna_wr && (sna_addr[13:12] == 2'b00));
	assign spr_wr_addr = (sna_wr ? sna_addr[11:0] : A[11:0]);
	assign spr_wr_data = (sna_wr ? sna_data[3:0] : D_in[3:0]);
	genvar _gv_gi_2;
	generate
		for (_gv_gi_2 = 0; _gv_gi_2 < 16; _gv_gi_2 = _gv_gi_2 + 1) begin : g_sprview
			localparam gi = _gv_gi_2;
			assign spr_x_view[gi * 10+:10] = {spr_x_hi[gi], spr_x_lo[gi]};
			assign spr_y_view[gi * 9+:9] = {spr_y_hi[gi], spr_y_lo[gi]};
			assign spr_mag_view[gi * 4+:4] = spr_mag[gi][3:0];
		end
		for (_gv_gi_2 = 0; _gv_gi_2 < 15; _gv_gi_2 = _gv_gi_2 + 1) begin : g_sprpal
			localparam gi = _gv_gi_2;
			assign spr_pal_view[gi * 12+:12] = pal[17 + gi];
		end
	endgenerate
	initial begin
		pri_r = 8'd0;
		splt_r = 8'd0;
		sscr_r = 8'd0;
		ivr_r = 8'b00000001;
		ssa_hi_r = 8'd0;
		ssa_lo_r = 8'd0;
		dcsr_stat = 1'b0;
		dcsr_flags = 3'd0;
		dcsr_ena = 3'd0;
		leg_inkr_q = {80 {1'b1}};
		leg_border_q = 5'b11111;
		import_pending = 1'b1;
		pal_r = 12'd0;
		ppr0_dec_q = 1'b0;
		ppr1_dec_q = 1'b0;
		ppr2_dec_q = 1'b0;
		ppr0_wr_r = 1'b0;
		ppr1_wr_r = 1'b0;
		ppr2_wr_r = 1'b0;
	end
endmodule
