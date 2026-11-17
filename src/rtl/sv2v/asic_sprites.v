`default_nettype wire
module asic_sprites (
	CLOCK,
	PIXEN,
	CLKEN,
	HWRAP,
	nRESET,
	LINE,
	ROW,
	SPR_X,
	SPR_Y,
	SPR_MAG,
	SPR_PAL,
	ACC_EN,
	ACC_IDX,
	spr_wr_en,
	spr_wr_addr,
	spr_wr_data,
	FQ_REQ,
	FQ_ADDR,
	FQ_DATA,
	FQ_ACK,
	SPR_EN,
	SPR_RGB,
	SPR_IDX,
	SPR_WIN
);
	parameter [9:0] H_ORIGIN_DOTS = 10'd0;
	input CLOCK;
	input PIXEN;
	input CLKEN;
	input HWRAP;
	input nRESET;
	input [6:0] LINE;
	input [4:0] ROW;
	input [159:0] SPR_X;
	input [143:0] SPR_Y;
	input [63:0] SPR_MAG;
	input [179:0] SPR_PAL;
	input ACC_EN;
	input [3:0] ACC_IDX;
	input spr_wr_en;
	input [11:0] spr_wr_addr;
	input [3:0] spr_wr_data;
	output reg FQ_REQ;
	output reg [10:0] FQ_ADDR;
	input [7:0] FQ_DATA;
	input FQ_ACK;
	output wire SPR_EN;
	output wire [11:0] SPR_RGB;
	output wire [3:0] SPR_IDX;
	output wire [15:0] SPR_WIN;
	wire unused = &{ROW[4:3], 1'b0};
	wire [9:0] vline = {LINE, ROW[2:0]};
	reg [9:0] c_xa [0:15];
	reg c_xneg [0:15];
	reg [8:0] c_xmag [0:15];
	reg [1:0] c_xc [0:15];
	reg [1:0] c_yc [0:15];
	reg [6:0] c_wid [0:15];
	reg [9:0] c_hgt [0:15];
	reg [2:0] c_ysh [0:15];
	reg [2:0] c_xsh [0:15];
	reg [9:0] c_diff [0:15];
	reg [3:0] c_srow [0:15];
	reg [15:0] c_lact;
	reg [15:0] c_ena;
	integer i;
	always @(*)
		for (i = 0; i < 16; i = i + 1)
			begin
				c_xa[i] = SPR_X[i * 10+:10];
				c_xneg[i] = &SPR_X[(i * 10) + 9-:2];
				c_xmag[i] = ~SPR_X[i * 10+:10] + 10'd1;
				c_xc[i] = SPR_MAG[(i * 4) + 3-:2];
				c_yc[i] = SPR_MAG[(i * 4) + 1-:2];
				c_xsh[i] = (c_xc[i] == 2'd1 ? 3'd0 : (c_xc[i] == 2'd2 ? 3'd1 : 3'd2));
				c_ysh[i] = (c_yc[i] == 2'd1 ? 3'd0 : (c_yc[i] == 2'd2 ? 3'd1 : 3'd2));
				c_wid[i] = 7'd16 << c_xsh[i];
				c_hgt[i] = 10'd16 << c_ysh[i];
				c_diff[i] = vline - {{2 {SPR_Y[(i * 9) + 8]}}, SPR_Y[i * 9+:8]};
				c_ena[i] = (c_xc[i] != 2'd0) && (c_yc[i] != 2'd0);
				c_lact[i] = c_ena[i] && (c_diff[i] < c_hgt[i]);
				c_srow[i] = c_diff[i][5:0] >> c_ysh[i];
			end
	reg [9:0] hp;
	reg [15:0] sx_on;
	reg [111:0] sx_cnt;
	reg [159:0] xs_q;
	reg [3:0] blank_cnt [0:15];
	localparam [9:0] HP_SEAM = 10'd0 - H_ORIGIN_DOTS;
	reg [15:0] c_xeq;
	reg [15:0] c_xleft;
	reg [15:0] c_chg;
	reg [15:0] c_wact;
	reg [3:0] c_spix [0:15];
	reg [15:0] n_on;
	reg [111:0] n_cnt;
	function [3:0] source_pixel;
		input [5:0] offset;
		input [1:0] mag_code;
		case (mag_code)
			2'd1: source_pixel = offset[3:0];
			2'd2: source_pixel = offset[4:1];
			default: source_pixel = offset[5:2];
		endcase
	endfunction
	always @(*) begin
		for (i = 0; i < 16; i = i + 1)
			begin
				c_xeq[i] = !c_xneg[i] && (hp == c_xa[i]);
				c_xleft[i] = ((hp == 10'd0) && c_xneg[i]) && ({2'b00, c_xmag[i]} < {4'b0000, c_wid[i]});
				c_chg[i] = xs_q[i * 10+:10] != c_xa[i];
				c_spix[i] = (c_xleft[i] ? source_pixel(c_xmag[i][5:0], c_xc[i]) : (c_xeq[i] ? 4'd0 : source_pixel(sx_cnt[i * 7+:6], c_xc[i])));
				n_on[i] = (c_xleft[i] || c_xeq[i]) || ((sx_on[i] && !c_chg[i]) && ({1'b0, sx_cnt[i * 7+:7]} != c_wid[i]));
				if (c_xleft[i])
					n_cnt[i * 7+:7] = {1'b0, c_xmag[i][5:0]} + 7'd1;
				else if (c_xeq[i])
					n_cnt[i * 7+:7] = 7'd1;
				else if ((sx_on[i] && !c_chg[i]) && ({1'b0, sx_cnt[i * 7+:7]} != c_wid[i]))
					n_cnt[i * 7+:7] = sx_cnt[i * 7+:7] + 7'd1;
				else
					n_cnt[i * 7+:7] = sx_cnt[i * 7+:7];
			end
		c_wact = n_on & ~c_chg;
	end
	always @(posedge CLOCK)
		if (!nRESET) begin
			hp <= HP_SEAM;
			sx_on <= 16'd0;
			sx_cnt <= 112'd0;
			xs_q <= 160'd0;
		end
		else if (PIXEN) begin
			if (CLKEN && HWRAP) begin
				hp <= HP_SEAM;
				sx_on <= 16'd0;
				sx_cnt <= 112'd0;
				xs_q <= SPR_X;
			end
			else begin
				hp <= hp + 10'd1;
				sx_on <= n_on;
				sx_cnt <= n_cnt;
				xs_q <= SPR_X;
			end
		end
	always @(posedge CLOCK)
		if (!nRESET)
			for (i = 0; i < 16; i = i + 1)
				blank_cnt[i] <= 4'd0;
		else
			for (i = 0; i < 16; i = i + 1)
				if (ACC_EN && (ACC_IDX == i[3:0]))
					blank_cnt[i] <= 4'd2;
				else if (PIXEN && (blank_cnt[i] != 4'd0))
					blank_cnt[i] <= blank_cnt[i] - 4'd1;
	reg [7:0] rb_dat [0:255];
	reg [255:0] sreq;
	reg [255:0] sdone;
	reg [127:0] srowtag;
	reg [31:0] sval;
	reg [15:0] abit;
	reg d1w;
	reg d2w;
	reg [15:0] c_retarget;
	always @(*)
		for (i = 0; i < 16; i = i + 1)
			c_retarget[i] = ((!d1w && !(CLKEN && HWRAP)) && c_lact[i]) && (!sval[{i[3:0], abit[i]}] || (srowtag[{i[3:0], abit[i]} * 4+:4] != c_srow[i]));
	reg [15:0] c_predok;
	reg [3:0] c_predrow [0:15];
	reg [9:0] c_entrydiff [0:15];
	always @(*)
		for (i = 0; i < 16; i = i + 1)
			begin
				c_entrydiff[i] = 10'd0 - {{2 {SPR_Y[(i * 9) + 8]}}, SPR_Y[i * 9+:8]};
				if (c_lact[i]) begin
					c_predok[i] = (c_diff[i] + 10'd1) < c_hgt[i];
					c_predrow[i] = c_srow[i] + 4'd1;
				end
				else begin
					c_predok[i] = c_ena[i] && (!SPR_Y[(i * 9) + 8] || (c_entrydiff[i] < c_hgt[i]));
					c_predrow[i] = (SPR_Y[(i * 9) + 8] ? c_entrydiff[i][5:0] >> c_ysh[i] : 4'd0);
				end
			end
	reg [15:0] c_repredict;
	always @(*)
		for (i = 0; i < 16; i = i + 1)
			c_repredict[i] = (((!d1w && !(CLKEN && HWRAP)) && !c_retarget[i]) && c_predok[i]) && (!sval[{i[3:0], ~abit[i]}] || (srowtag[{i[3:0], ~abit[i]} * 4+:4] != c_predrow[i]));
	reg [7:0] walk;
	reg walk_act;
	wire [3:0] wk_s = walk[6:3];
	wire wk_spec = walk[7];
	wire [2:0] wk_byte = walk[2:0];
	wire wk_go = (walk_act && c_ena[wk_s]) && (walk[7] ? c_predok[wk_s] && sval[{wk_s[3:0], ~abit[wk_s]}] : c_lact[wk_s]);
	wire wk_wrap = &walk[6:3];
	wire [3:0] wk_s_nxt = walk[6:3] + 4'd1;
	wire wk_bank = (wk_spec ? ~abit[wk_s] : abit[wk_s]);
	wire [7:0] wk_word = {wk_s, wk_bank, wk_byte};
	wire [3:0] wk_row = (wk_spec ? srowtag[{wk_s[3:0], ~abit[wk_s]} * 4+:4] : c_srow[wk_s]);
	reg [7:0] fq_tag;
	reg [3:0] fq_row;
	reg fq_acc;
	wire do_pop = FQ_REQ && FQ_ACK;
	wire fq_stale = fq_acc || (srowtag[fq_tag[7:3] * 4+:4] != fq_row);
	wire fq_acc_hit = ACC_EN && (ACC_IDX == fq_tag[7:4]);
	wire fq_repredict = c_repredict[fq_tag[7:4]] && (fq_tag[3] != abit[fq_tag[7:4]]);
	wire [7:0] pb_word = wk_word;
	wire pb_fresh = ((((wk_go && !d1w) && !c_retarget[wk_s]) && !(wk_spec && c_repredict[wk_s])) && !sreq[pb_word]) && !sdone[pb_word];
	always @(posedge CLOCK)
		if (!nRESET) begin
			sreq <= 256'd0;
			sdone <= 256'd0;
			srowtag <= 128'd0;
			sval <= 32'd0;
			abit <= 16'd0;
			d1w <= 1'b0;
			d2w <= 1'b0;
			walk <= 8'd0;
			walk_act <= 1'b0;
			FQ_REQ <= 1'b0;
			FQ_ADDR <= 11'd0;
			fq_tag <= 8'd0;
			fq_row <= 4'd0;
			fq_acc <= 1'b0;
		end
		else begin
			d1w <= CLKEN && HWRAP;
			d2w <= d1w;
			for (i = 0; i < 16; i = i + 1)
				if (d1w || c_retarget[i]) begin
					if (!c_ena[i]) begin
						sval[{i[3:0], abit[i]}] <= 1'b0;
						sval[{i[3:0], ~abit[i]}] <= 1'b0;
					end
					else if (!c_lact[i]) begin
						if (c_predok[i] && (!sval[{i[3:0], ~abit[i]}] || (srowtag[{i[3:0], ~abit[i]} * 4+:4] != c_predrow[i]))) begin
							sdone[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
							sreq[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
							srowtag[{i[3:0], ~abit[i]} * 4+:4] <= c_predrow[i];
							sval[{i[3:0], ~abit[i]}] <= 1'b1;
						end
						else if (!c_predok[i])
							sval[{i[3:0], ~abit[i]}] <= 1'b0;
					end
					else if (sval[{i[3:0], ~abit[i]}] && (srowtag[{i[3:0], ~abit[i]} * 4+:4] == c_srow[i])) begin
						abit[i] <= ~abit[i];
						if (c_predok[i]) begin
							sdone[{i[3:0], abit[i]} * 8+:8] <= 8'd0;
							sreq[{i[3:0], abit[i]} * 8+:8] <= 8'd0;
							srowtag[{i[3:0], abit[i]} * 4+:4] <= c_predrow[i];
							sval[{i[3:0], abit[i]}] <= 1'b1;
						end
						else
							sval[{i[3:0], abit[i]}] <= 1'b0;
					end
					else if (sval[{i[3:0], abit[i]}] && (srowtag[{i[3:0], abit[i]} * 4+:4] == c_srow[i])) begin
						if (c_predok[i]) begin
							sdone[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
							sreq[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
							srowtag[{i[3:0], ~abit[i]} * 4+:4] <= c_predrow[i];
							sval[{i[3:0], ~abit[i]}] <= 1'b1;
						end
						else
							sval[{i[3:0], ~abit[i]}] <= 1'b0;
					end
					else begin
						sdone[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
						sreq[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
						srowtag[{i[3:0], ~abit[i]} * 4+:4] <= c_srow[i];
						sval[{i[3:0], ~abit[i]}] <= 1'b1;
						abit[i] <= ~abit[i];
						if (c_predok[i]) begin
							sdone[{i[3:0], abit[i]} * 8+:8] <= 8'd0;
							sreq[{i[3:0], abit[i]} * 8+:8] <= 8'd0;
							srowtag[{i[3:0], abit[i]} * 4+:4] <= c_predrow[i];
							sval[{i[3:0], abit[i]}] <= 1'b1;
						end
						else
							sval[{i[3:0], abit[i]}] <= 1'b0;
					end
				end
				else if (c_repredict[i]) begin
					sdone[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
					sreq[{i[3:0], ~abit[i]} * 8+:8] <= 8'd0;
					srowtag[{i[3:0], ~abit[i]} * 4+:4] <= c_predrow[i];
					sval[{i[3:0], ~abit[i]}] <= 1'b1;
				end
			if (spr_wr_en) begin
				for (i = 0; i < 2; i = i + 1)
					if (sval[{spr_wr_addr[11:8], i[0]}] && (srowtag[{spr_wr_addr[11:8], i[0]} * 4+:4] == spr_wr_addr[7:4])) begin
						if (spr_wr_addr[0])
							rb_dat[{spr_wr_addr[11:8], i[0], spr_wr_addr[3:1]}][7:4] <= spr_wr_data;
						else
							rb_dat[{spr_wr_addr[11:8], i[0], spr_wr_addr[3:1]}][3:0] <= spr_wr_data;
					end
			end
			if (do_pop) begin
				FQ_REQ <= 1'b0;
				if ((((!d1w && !c_retarget[fq_tag[7:4]]) && !fq_stale) && !fq_acc_hit) && !fq_repredict) begin
					rb_dat[fq_tag] <= FQ_DATA;
					sdone[fq_tag] <= 1'b1;
				end
				else
					sreq[fq_tag] <= 1'b0;
			end
			if (!walk_act) begin
				if (d2w) begin
					walk_act <= 1'b1;
					walk <= 6'd0;
				end
			end
			else if (!FQ_REQ) begin
				if (pb_fresh) begin
					FQ_ADDR <= {wk_s, wk_row, wk_byte};
					fq_tag <= pb_word;
					fq_row <= wk_row;
					fq_acc <= ACC_EN && (ACC_IDX == pb_word[7:4]);
					FQ_REQ <= 1'b1;
					sreq[pb_word] <= 1'b1;
				end
				if (!c_ena[wk_s])
					walk <= {walk[7] ^ wk_wrap, wk_s_nxt, 3'd0};
				else
					walk <= walk + 8'd1;
			end
			else if (fq_acc_hit)
				fq_acc <= 1'b1;
		end
	reg [15:0] c_opq;
	reg [4:0] c_meta [0:15];
	reg [7:0] c_wsel [0:15];
	reg [7:0] c_word [0:15];
	reg [3:0] c_nibv [0:15];
	always @(*)
		for (i = 0; i < 16; i = i + 1)
			begin
				c_meta[i] = {i[3:0], abit[i]};
				c_wsel[i] = {i[3:0], abit[i], c_spix[i][3:1]};
				c_word[i] = rb_dat[c_wsel[i]];
				c_nibv[i] = (c_spix[i][0] ? c_word[i][7:4] : c_word[i][3:0]);
				c_opq[i] = (((((c_wact[i] && c_lact[i]) && sval[c_meta[i]]) && (srowtag[c_meta[i] * 4+:4] == c_srow[i])) && sdone[c_wsel[i]]) && (c_nibv[i] != 4'd0)) && (blank_cnt[i] == 4'd0);
			end
	reg win_found;
	reg [3:0] win_idx;
	reg [3:0] win_nib;
	always @(*) begin
		win_found = 1'b0;
		win_idx = 4'd0;
		win_nib = 4'd0;
		for (i = 15; i >= 0; i = i - 1)
			if (c_opq[i]) begin
				win_found = 1'b1;
				win_idx = i[3:0];
				win_nib = c_nibv[i];
			end
	end
	reg [11:0] win_word;
	always @(*)
		case (win_nib)
			4'd1: win_word = SPR_PAL[11:0];
			4'd2: win_word = SPR_PAL[23:12];
			4'd3: win_word = SPR_PAL[35:24];
			4'd4: win_word = SPR_PAL[47:36];
			4'd5: win_word = SPR_PAL[59:48];
			4'd6: win_word = SPR_PAL[71:60];
			4'd7: win_word = SPR_PAL[83:72];
			4'd8: win_word = SPR_PAL[95:84];
			4'd9: win_word = SPR_PAL[107:96];
			4'd10: win_word = SPR_PAL[119:108];
			4'd11: win_word = SPR_PAL[131:120];
			4'd12: win_word = SPR_PAL[143:132];
			4'd13: win_word = SPR_PAL[155:144];
			4'd14: win_word = SPR_PAL[167:156];
			4'd15: win_word = SPR_PAL[179:168];
			default: win_word = 12'd0;
		endcase
	assign SPR_EN = win_found;
	assign SPR_IDX = win_idx;
	assign SPR_WIN = c_wact & c_lact;
	assign SPR_RGB = {win_word[7:4], win_word[11:8], win_word[3:0]};
endmodule
