module playcity (
	clock,
	reset,
	ena,
	phi_n,
	phi_en,
	addr,
	din,
	dout,
	cpu_di,
	m1_n,
	iorq_n,
	rd_n,
	wr_n,
	int_n,
	nmi,
	cursor,
	audio_l,
	audio_r
);
	input clock;
	input reset;
	input ena;
	input phi_n;
	input phi_en;
	input [15:0] addr;
	input [7:0] din;
	output wire [7:0] dout;
	input [7:0] cpu_di;
	input m1_n;
	input iorq_n;
	input rd_n;
	input wr_n;
	output wire int_n;
	output wire nmi;
	input cursor;
	output wire [7:0] audio_l;
	output wire [7:0] audio_r;
	wire soft_reset = ((ena && ~iorq_n) && m1_n) && (addr[15:0] == 16'hf8ff);
	wire reset_n = ~(soft_reset | reset) & ena;
	wire ctc_ce_n = ~(((ena && ~iorq_n) && m1_n) && (addr[15:2] == 14'h3e20));
	wire ay_sel = (((ena && ~iorq_n) && ~wr_n) && (addr[15:9] == 7'h7c)) && (addr[7:4] == 4'h8);
	wire ctc_counter_0_to;
	wire ctc_counter_3_trg;
	z80ctc_top z80ctc(
		.clock(clock),
		.clock_ena(phi_en),
		.reset(~reset_n),
		.din(din),
		.cpu_din(cpu_di),
		.dout(dout),
		.ce_n(ctc_ce_n),
		.cs(addr[1:0]),
		.m1_n(m1_n),
		.iorq_n(iorq_n),
		.rd_n(rd_n),
		.int_n(int_n),
		.trg0(phi_n),
		.to0(ctc_counter_0_to),
		.trg1(cursor),
		.to1(nmi),
		.trg2(phi_n),
		.to2(ctc_counter_3_trg),
		.trg3(ctc_counter_3_trg)
	);
	wire ay_clock = ctc_counter_0_to | phi_n;
	reg ay_ce;
	always @(posedge clock) begin : sv2v_autoblock_1
		reg ay_clock_d;
		ay_clock_d <= ay_clock;
		ay_ce <= ~ay_clock_d & ay_clock;
	end
	wire [7:0] chl_a;
	wire [7:0] chl_b;
	wire [7:0] chl_c;
	wire [9:0] al = ({2'b00, chl_a} + {2'b00, chl_b}) + {2'b00, chl_c};
	assign audio_l = al[9:2] + al[9:4];
	YM2149 psg_left(
		.RESET(~reset_n),
		.CLK(clock),
		.CE(ay_ce),
		.SEL(1),
		.MODE(0),
		.BC(addr[8]),
		.BDIR(ay_sel & addr[2]),
		.DI(din),
		.CHANNEL_A(chl_a),
		.CHANNEL_B(chl_b),
		.CHANNEL_C(chl_c),
		.SNA_LOAD(1'b0),
		.SNA_ADDR(4'd0),
		.SNA_REGS(128'd0)
	);
	wire [7:0] chr_a;
	wire [7:0] chr_b;
	wire [7:0] chr_c;
	wire [9:0] ar = ({2'b00, chr_a} + {2'b00, chr_b}) + {2'b00, chr_c};
	assign audio_r = ar[9:2] + ar[9:4];
	YM2149 psg_right(
		.RESET(~reset_n),
		.CLK(clock),
		.CE(ay_ce),
		.SEL(1),
		.MODE(0),
		.BC(addr[8]),
		.BDIR(ay_sel & addr[3]),
		.DI(din),
		.CHANNEL_A(chr_a),
		.CHANNEL_B(chr_b),
		.CHANNEL_C(chr_c),
		.SNA_LOAD(1'b0),
		.SNA_ADDR(4'd0),
		.SNA_REGS(128'd0)
	);
endmodule
