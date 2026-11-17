module syncgen_sync (
	clk,
	CCLK_EN_N,
	RESET_N,
	MREQ_N,
	M1_N,
	IORQ_N,
	HSYNC_I,
	HSYNC_RESTART_I,
	VSYNC_I,
	irq_reset,
	HSYNC_O,
	VSYNC_O,
	SYNC_N,
	INT_N,
	HCNTLT28,
	mode_sync_en,
	SNAP_INTCNT,
	SNAP_HCNT
);
	input clk;
	input CCLK_EN_N;
	input RESET_N;
	input MREQ_N;
	input M1_N;
	input IORQ_N;
	input HSYNC_I;
	input HSYNC_RESTART_I;
	input VSYNC_I;
	input irq_reset;
	output wire HSYNC_O;
	output wire VSYNC_O;
	output wire SYNC_N;
	output reg INT_N;
	output wire HCNTLT28;
	output reg mode_sync_en;
	output wire [5:0] SNAP_INTCNT;
	output wire [4:0] SNAP_HCNT;
	reg [5:0] intcnt;
	reg [5:0] intcnt_reg;
	reg [5:0] intcnt_next;
	reg [4:0] hcnt;
	reg [4:0] hcnt_reg;
	reg [4:0] hcnt_next;
	reg [3:0] hdelay;
	reg [3:0] hdelay_reg;
	reg vsync_d;
	wire hsync_n = ~HSYNC_I;
	reg hsync_n_d;
	reg vsync_o_d;
	wire irqack_rst;
	always @(posedge clk) begin
		hsync_n_d <= hsync_n;
		if (CCLK_EN_N) begin
			vsync_d <= VSYNC_I;
			vsync_o_d <= VSYNC_O;
		end
	end
	wire hcnt_cnt = ~hsync_n_d & hsync_n;
	assign VSYNC_O = (hcnt[2] & ~hcnt[3]) & ~hcnt[4];
	assign HCNTLT28 = ~((hcnt[2] & hcnt[3]) & hcnt[4]);
	wire hcnt_res0 = ~RESET_N | (((hcnt_cnt & hcnt_next[2]) & hcnt_next[3]) & hcnt_next[4]);
	wire hcnt_res1 = VSYNC_I & ~vsync_d;
	always @(*) begin
		hcnt = hcnt_reg;
		if (hcnt_cnt)
			hcnt = hcnt_next;
		if (hcnt_res0)
			hcnt[0] = 0;
		if (hcnt_res1)
			hcnt[4:1] = 0;
	end
	always @(posedge clk) begin
		hcnt_reg <= hcnt;
		case (hcnt)
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
	wire hdelay_res0 = (hsync_n | HSYNC_RESTART_I) | hdelay_reg[3];
	wire hdelay_res1 = hsync_n | HSYNC_RESTART_I;
	reg hdelay_res0_d;
	reg hdelay2d;
	always @(posedge clk) begin
		hdelay_res0_d <= hdelay_res0;
		hdelay2d <= hdelay[2];
	end
	always @(*) begin
		hdelay = hdelay_reg;
		mode_sync_en = (~hdelay_res0_d & hdelay_res0) & hdelay2d;
		if (hdelay_res0)
			hdelay[2:0] = 0;
		if (hdelay_res1)
			hdelay[3] = 0;
	end
	always @(posedge clk)
		if (hdelay_res0 | hdelay_res1)
			hdelay_reg <= hdelay;
		else if (CCLK_EN_N)
			case (hdelay)
				4'h0: hdelay_reg <= 4'h1;
				4'h1: hdelay_reg <= 4'h6;
				4'h6: hdelay_reg <= 4'h7;
				4'h7: hdelay_reg <= 4'h4;
				4'h4: hdelay_reg <= 4'h5;
				4'h5: hdelay_reg <= 4'h8;
				default:
					;
			endcase
	assign HSYNC_O = hdelay[2];
	assign SYNC_N = ~(VSYNC_O ^ HSYNC_O);
	wire intcntclr_52;
	wire intcnt52 = ((hcnt_cnt & intcnt_next[2]) & intcnt_next[4]) & intcnt_next[5];
	rslatch #(.PRIO_SET(0)) intcntclr_52_l(
		.clock(clk),
		.s(intcnt52),
		.r(~hsync_n),
		.q(intcntclr_52)
	);
	wire intcntclr_4 = VSYNC_O & ~vsync_o_d;
	wire intcnt_res0 = (intcntclr_52 | intcntclr_4) | irq_reset;
	wire intcnt_res1 = intcnt_res0 | irqack_rst;
	always @(*) begin
		intcnt = intcnt_reg;
		if (intcnt_res0)
			intcnt[4:0] = 0;
		else if (hcnt_cnt)
			intcnt = intcnt_next;
		if (intcnt_res1)
			intcnt[5] = 0;
	end
	always @(posedge clk) begin
		intcnt_reg <= intcnt;
		intcnt_next <= intcnt + 1'd1;
	end
	rslatch irqack_rst_l(
		.clock(clk),
		.s(~((INT_N | IORQ_N) | M1_N)),
		.r(M1_N),
		.q(irqack_rst)
	);
	wire int_reset = irq_reset | irqack_rst;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg cnt5;
		cnt5 <= intcnt[5];
		if (int_reset)
			INT_N <= 1;
		else if (~intcnt[5] & cnt5)
			INT_N <= 0;
	end
	assign SNAP_INTCNT = intcnt_reg;
	assign SNAP_HCNT = hcnt_reg;
endmodule
