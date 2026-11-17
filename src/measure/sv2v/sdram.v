module sdram (
	SDRAM_DQ,
	SDRAM_A,
	SDRAM_DQML,
	SDRAM_DQMH,
	SDRAM_BA,
	SDRAM_nCS,
	SDRAM_nWE,
	SDRAM_nRAS,
	SDRAM_nCAS,
	SDRAM_CLK,
	SDRAM_CKE,
	init,
	clk,
	clkref,
	bank,
	din,
	dout,
	addr,
	oe,
	we,
	cart_req,
	cart_wr,
	cart_bank,
	cart_addr,
	cart_din,
	cart_dout,
	cart_ack,
	cart_grant,
	vram_dout,
	vram_addr,
	vram_bank,
	tape_addr,
	tape_din,
	tape_dout,
	tape_wr,
	tape_wr_ack,
	tape_rd,
	tape_rd_ack
);
	inout [15:0] SDRAM_DQ;
	output reg [12:0] SDRAM_A;
	output wire SDRAM_DQML;
	output wire SDRAM_DQMH;
	output reg [1:0] SDRAM_BA;
	output wire SDRAM_nCS;
	output reg SDRAM_nWE;
	output reg SDRAM_nRAS;
	output reg SDRAM_nCAS;
	output wire SDRAM_CLK;
	output wire SDRAM_CKE;
	input init;
	input clk;
	input clkref;
	input [1:0] bank;
	input [7:0] din;
	output wire [7:0] dout;
	input [22:0] addr;
	input oe;
	input we;
	input cart_req;
	input cart_wr;
	input [1:0] cart_bank;
	input [22:0] cart_addr;
	input [7:0] cart_din;
	output reg [7:0] cart_dout;
	output reg cart_ack;
	output reg cart_grant;
	output reg [15:0] vram_dout;
	input [22:0] vram_addr;
	input [1:0] vram_bank;
	input [22:0] tape_addr;
	input [7:0] tape_din;
	output reg [7:0] tape_dout;
	input tape_wr;
	output reg tape_wr_ack;
	input tape_rd;
	output reg tape_rd_ack;
	assign SDRAM_CKE = 1;
	assign SDRAM_nCS = 0;
	assign {SDRAM_DQMH, SDRAM_DQML} = SDRAM_A[12:11];
	reg [7:0] ram_dout;
	assign dout = (oe | we ? ram_dout : 8'hff);
	localparam RASCAS_DELAY = 3'd2;
	localparam BURST_LENGTH = 3'b000;
	localparam ACCESS_TYPE = 1'b0;
	localparam CAS_LATENCY = 3'd2;
	localparam OP_MODE = 2'b00;
	localparam NO_WRITE_BURST = 1'b1;
	localparam MODE = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};
	localparam STATE_IDLE = 3'd0;
	localparam STATE_START = 3'd1;
	localparam STATE_CONT = STATE_START + RASCAS_DELAY;
	localparam STATE_READ = (STATE_CONT + CAS_LATENCY) + 3'd1;
	localparam STATE_READY = STATE_READ + 3'd1;
	localparam STATE_LAST = 3'd7;
	reg [2:0] q;
	reg [22:0] a;
	reg wr;
	reg ram_req = 0;
	reg vram_req = 0;
	reg tape_req = 0;
	reg cart_active = 0;
	initial cart_grant = 0;
	reg [1:0] active_bank;
	reg [22:1] vram_cached_addr;
	reg [1:0] vram_cached_bank;
	reg vram_cached_valid = 0;
	reg [7:0] cart_write_data;
	reg [7:0] tape_write_data;
	reg [5:0] cart_grants_since_refresh = 0;
	reg refresh_due = 0;
	localparam [1:0] TAPE_BANK = 2'b11;
	localparam [22:0] TAPE_BASE = 23'h100000;
	wire [22:0] tape_phys_addr = tape_addr + TAPE_BASE;
	localparam MODE_NORMAL = 2'b00;
	localparam MODE_RESET = 2'b01;
	localparam MODE_LDM = 2'b10;
	localparam MODE_PRE = 2'b11;
	reg [1:0] mode = MODE_RESET;
	reg [4:0] reset = 5'h1f;
	reg init_old = 0;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg old_rd;
		reg old_we;
		reg old_ref;
		old_rd <= oe;
		old_we <= we;
		old_ref <= clkref;
		cart_grant <= 0;
		if (((reset != 0) || init) || init_old)
			vram_cached_valid <= 0;
		if (q == STATE_IDLE) begin
			ram_req <= 0;
			vram_req <= 0;
			tape_req <= 0;
			cart_active <= 0;
			wr <= 0;
			if (((((mode == MODE_NORMAL) && (reset == 0)) && !init) && !init_old) && ((~old_rd & oe) | (~old_we & we))) begin
				ram_req <= 1;
				wr <= we;
				a <= addr;
				active_bank <= bank;
				if (((we && vram_cached_valid) && (bank == vram_cached_bank)) && (addr[22:1] == vram_cached_addr))
					vram_cached_valid <= 0;
			end
			else if (((((mode == MODE_NORMAL) && (reset == 0)) && !init) && !init_old) && refresh_due) begin
				refresh_due <= 0;
				cart_grants_since_refresh <= 0;
			end
			else if (((((mode == MODE_NORMAL) && (reset == 0)) && !init) && !init_old) && cart_req) begin
				cart_active <= 1;
				cart_grant <= 1;
				wr <= cart_wr;
				a <= cart_addr;
				active_bank <= cart_bank;
				cart_write_data <= cart_din;
				if (((cart_wr && vram_cached_valid) && (cart_bank == vram_cached_bank)) && (cart_addr[22:1] == vram_cached_addr))
					vram_cached_valid <= 0;
				if (cart_grants_since_refresh == 6'd31) begin
					cart_grants_since_refresh <= 6'd32;
					refresh_due <= 1;
				end
				else
					cart_grants_since_refresh <= cart_grants_since_refresh + 1'd1;
			end
			else if (((((mode == MODE_NORMAL) && (reset == 0)) && !init) && !init_old) && (tape_rd | tape_wr)) begin
				tape_req <= 1;
				wr <= tape_wr;
				a <= tape_phys_addr;
				tape_write_data <= tape_din;
				active_bank <= TAPE_BANK;
				if (((tape_wr && vram_cached_valid) && (TAPE_BANK == vram_cached_bank)) && (tape_phys_addr[22:1] == vram_cached_addr))
					vram_cached_valid <= 0;
			end
			else if (((((mode == MODE_NORMAL) && (reset == 0)) && !init) && !init_old) && ((!vram_cached_valid || (vram_cached_bank != vram_bank)) || (vram_cached_addr != vram_addr[22:1]))) begin
				vram_req <= 1;
				vram_cached_valid <= 1;
				vram_cached_bank <= vram_bank;
				vram_cached_addr <= vram_addr[22:1];
				active_bank <= vram_bank;
				a <= vram_addr;
			end
			else if (mode == MODE_NORMAL) begin
				refresh_due <= 0;
				cart_grants_since_refresh <= 0;
			end
		end
		q <= q + 3'd1;
		if (~old_ref & clkref)
			q <= 0;
	end
	always @(posedge clk) begin
		init_old <= init;
		if (init_old & ~init)
			reset <= 5'h1f;
		else if (q == STATE_LAST) begin
			if (reset != 0) begin
				reset <= reset - 5'd1;
				if (reset == 14)
					mode <= MODE_PRE;
				else if (reset == 3)
					mode <= MODE_LDM;
				else
					mode <= MODE_RESET;
			end
			else
				mode <= MODE_NORMAL;
		end
	end
	localparam CMD_NOP = 3'b111;
	localparam CMD_ACTIVE = 3'b011;
	localparam CMD_READ = 3'b101;
	localparam CMD_WRITE = 3'b100;
	localparam CMD_BURST_TERMINATE = 3'b110;
	localparam CMD_PRECHARGE = 3'b010;
	localparam CMD_AUTO_REFRESH = 3'b001;
	localparam CMD_LOAD_MODE = 3'b000;
	reg [15:0] sdram_dq_out;
	reg sdram_dq_oe;
	assign SDRAM_DQ = (sdram_dq_oe ? sdram_dq_out : 16'hzzzz);
	always @(posedge clk) begin : sv2v_autoblock_2
		reg [15:0] data;
		casex ({((ram_req | vram_req) | tape_req) | cart_active, wr, mode, q})
			{2'b1x, MODE_NORMAL, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_ACTIVE;
			{2'b11, MODE_NORMAL, STATE_CONT}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_WRITE;
			{2'b10, MODE_NORMAL, STATE_CONT}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_READ;
			{2'b0x, MODE_NORMAL, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_AUTO_REFRESH;
			{2'bxx, MODE_LDM, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_LOAD_MODE;
			{2'bxx, MODE_PRE, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_PRECHARGE;
			default: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_NOP;
		endcase
		casex ({((ram_req | vram_req) | tape_req) | cart_active, mode, q})
			{1'b1, MODE_NORMAL, STATE_START}: SDRAM_A <= a[21:9];
			{1'b1, MODE_NORMAL, STATE_CONT}: SDRAM_A <= {~a[0] & wr, a[0] & wr, 2'b10, a[22], a[8:1]};
			{1'bx, MODE_LDM, STATE_START}: SDRAM_A <= MODE;
			{1'bx, MODE_PRE, STATE_START}: SDRAM_A <= 13'b0010000000000;
			default: SDRAM_A <= 13'b0000000000000;
		endcase
		if (q == STATE_START) begin
			SDRAM_BA <= (mode == MODE_NORMAL ? active_bank : 2'b00);
			if (ram_req & wr)
				ram_dout <= din;
		end
		data <= SDRAM_DQ;
		sdram_dq_oe <= 0;
		if ((q == STATE_CONT) && wr) begin
			sdram_dq_out <= (tape_req ? {tape_write_data, tape_write_data} : (cart_active ? {cart_write_data, cart_write_data} : {din, din}));
			sdram_dq_oe <= 1;
		end
		tape_wr_ack <= 0;
		cart_ack <= 0;
		if ((q == STATE_READ) && cart_active) begin
			if (!wr)
				cart_dout <= (a[0] ? SDRAM_DQ[15:8] : SDRAM_DQ[7:0]);
			cart_ack <= 1;
		end
		if (((q == STATE_READ) && tape_req) && wr)
			tape_wr_ack <= 1;
		if (q == STATE_READY) begin
			if (~wr & ram_req)
				ram_dout <= (a[0] ? data[15:8] : data[7:0]);
			else if (vram_req)
				vram_dout <= data;
			else if (~wr & tape_req)
				tape_dout <= (a[0] ? data[15:8] : data[7:0]);
			if (tape_req && !wr)
				tape_rd_ack <= ~tape_rd_ack;
		end
	end
	altddio_out #(
		.extend_oe_disable("OFF"),
		.intended_device_family("Cyclone V"),
		.invert_output("OFF"),
		.lpm_hint("UNUSED"),
		.lpm_type("altddio_out"),
		.oe_reg("UNREGISTERED"),
		.power_up_high("OFF"),
		.width(1)
	) sdramclk_ddr(
		.datain_h(1'b0),
		.datain_l(1'b1),
		.outclock(clk),
		.dataout(SDRAM_CLK),
		.aclr(1'b0),
		.aset(1'b0),
		.oe(1'b1),
		.outclocken(1'b1),
		.sclr(1'b0),
		.sset(1'b0)
	);
endmodule
