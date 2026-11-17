module plus_mmu (
	clk,
	reset,
	plus_mode,
	gx4000,
	io_rd,
	io_wr,
	mem_rd,
	A,
	D,
	rom_en,
	exp_n,
	cart_valid,
	cart_page,
	cart_offset,
	cart_ready,
	cart_granted,
	cart_data,
	cart_busy,
	cart_own,
	cart_stall,
	cart_dout,
	asic_page_on,
	asic_unlocked,
	sna_load,
	sna_rmr2,
	sna_unlock,
	sna_ga_config,
	sna_romsel,
	sna_seq_state
);
	input clk;
	input reset;
	input plus_mode;
	input gx4000;
	input io_rd;
	input io_wr;
	input mem_rd;
	input [15:0] A;
	input [7:0] D;
	input rom_en;
	input exp_n;
	output reg cart_valid;
	output reg [4:0] cart_page;
	output reg [13:0] cart_offset;
	input cart_ready;
	input cart_granted;
	input [7:0] cart_data;
	input cart_busy;
	output reg cart_own;
	output reg cart_stall;
	output reg [7:0] cart_dout;
	output reg asic_page_on;
	output wire asic_unlocked;
	input sna_load;
	input [7:0] sna_rmr2;
	input sna_unlock;
	input [7:0] sna_ga_config;
	input [7:0] sna_romsel;
	input [4:0] sna_seq_state;
	localparam [1:0] CART_IDLE = 2'd0;
	localparam [1:0] CART_WAIT = 2'd1;
	localparam [1:0] CART_CAPTURE = 2'd2;
	localparam [1:0] CART_DONE = 2'd3;
	localparam [15:0] STALL_TIMEOUT = 16'd1024;
	wire unlocked;
	reg [1:0] rmr2_pos;
	reg [2:0] rmr2_page;
	reg [7:0] romsel;
	reg [1:0] cart_state;
	reg [15:0] stall_count;
	reg io_access_d;
	wire io_access = io_wr | io_rd;
	wire io_access_start = io_access & ~io_access_d;
	always @(posedge clk)
		if (reset)
			io_access_d <= 1'b0;
		else
			io_access_d <= io_access;
	wire unlock_write = (((plus_mode & io_access_start) & ~A[14]) & ~A[9]) & ~A[8];
	asic_unlock unlock_detector(
		.clk(clk),
		.RESET_N(~reset),
		.write_strobe(unlock_write),
		.write_data(D),
		.unlocked(unlocked),
		.sna_load(sna_load),
		.sna_unlock(sna_unlock),
		.sna_seq_state(sna_seq_state)
	);
	assign asic_unlocked = plus_mode & unlocked;
	reg lromen;
	reg hromen;
	wire low_hit = (plus_mode & ~lromen) & (A[15:14] == rmr2_pos);
	wire high_hit = (plus_mode & ~hromen) & (A[15:14] == 2'b11);
	wire window_hit = mem_rd & (low_hit | high_hit);
	reg [4:0] high_page;
	always @(*)
		if (romsel >= 8'd128)
			high_page = romsel[4:0];
		else if (gx4000)
			high_page = 5'd1;
		else if (romsel == 8'd7)
			high_page = 5'd3;
		else if (romsel == 8'd0)
			high_page = (exp_n ? 5'd3 : 5'd1);
		else
			high_page = 5'd1;
	always @(posedge clk)
		if (reset) begin
			rmr2_pos <= 2'b00;
			rmr2_page <= 3'd0;
			asic_page_on <= 1'b0;
			romsel <= 8'h00;
			lromen <= 1'b0;
			hromen <= 1'b0;
		end
		else if (sna_load) begin
			rmr2_pos <= (sna_rmr2[4:3] == 2'b11 ? 2'b00 : sna_rmr2[4:3]);
			rmr2_page <= sna_rmr2[2:0];
			asic_page_on <= sna_rmr2[4:3] == 2'b11;
			lromen <= sna_ga_config[2];
			hromen <= sna_ga_config[3];
			romsel <= sna_romsel;
		end
		else begin
			if (((plus_mode && io_access_start) && !A[15]) && A[14]) begin
				if ((D[7:5] == 3'b101) && unlocked) begin
					rmr2_pos <= (D[4:3] == 2'b11 ? 2'b00 : D[4:3]);
					rmr2_page <= D[2:0];
					asic_page_on <= D[4:3] == 2'b11;
				end
				else if ((D[7:5] == 3'b100) || ((D[7:5] == 3'b101) && !unlocked)) begin
					lromen <= D[2];
					hromen <= D[3];
				end
			end
			if (io_wr && !A[13])
				romsel <= D;
		end
	always @(posedge clk)
		if (reset) begin
			cart_state <= CART_IDLE;
			cart_valid <= 1'b0;
			cart_page <= 5'd0;
			cart_offset <= 14'd0;
			cart_own <= 1'b0;
			cart_stall <= 1'b0;
			cart_dout <= 8'hff;
			stall_count <= 16'd0;
		end
		else
			case (cart_state)
				CART_IDLE: begin
					cart_own <= 1'b0;
					cart_stall <= 1'b0;
					stall_count <= 16'd0;
					if (window_hit) begin
						cart_valid <= 1'b1;
						cart_page <= (low_hit ? {2'b00, rmr2_page} : high_page);
						cart_offset <= A[13:0];
						cart_own <= 1'b1;
						cart_stall <= 1'b1;
						cart_state <= CART_WAIT;
					end
				end
				CART_WAIT: begin
					if (cart_granted)
						cart_stall <= 1'b0;
					if (cart_ready) begin
						cart_valid <= 1'b0;
						cart_state <= CART_CAPTURE;
					end
					else if (!window_hit) begin
						cart_valid <= 1'b0;
						cart_stall <= 1'b0;
						cart_dout <= 8'hff;
						cart_state <= CART_IDLE;
					end
					else if (cart_busy)
						stall_count <= 16'd0;
					else if (stall_count == STALL_TIMEOUT) begin
						cart_valid <= 1'b0;
						cart_stall <= 1'b0;
						cart_dout <= 8'hff;
						cart_state <= (window_hit ? CART_DONE : CART_IDLE);
					end
					else
						stall_count <= stall_count + 16'd1;
				end
				CART_CAPTURE: begin
					cart_dout <= cart_data;
					cart_stall <= 1'b0;
					cart_state <= CART_DONE;
				end
				CART_DONE:
					if (!window_hit) begin
						cart_own <= 1'b0;
						cart_state <= CART_IDLE;
					end
			endcase
	initial begin
		rmr2_pos = 2'b00;
		rmr2_page = 3'd0;
		asic_page_on = 1'b0;
		romsel = 8'h00;
		lromen = 1'b0;
		hromen = 1'b0;
		cart_state = CART_IDLE;
		cart_valid = 1'b0;
		cart_page = 5'd0;
		cart_offset = 14'd0;
		cart_own = 1'b0;
		cart_stall = 1'b0;
		cart_dout = 8'hff;
		stall_count = 16'd0;
	end
endmodule
