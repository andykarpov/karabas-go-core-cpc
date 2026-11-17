module asic_dma (
	clk,
	reset,
	cclk_en_p,
	cclk_en_n,
	hsync,
	sna_load,
	sna_loop_cnt0,
	sna_loop_cnt1,
	sna_loop_cnt2,
	sna_loop_addr0,
	sna_loop_addr1,
	sna_loop_addr2,
	sna_pause_cnt0,
	sna_pause_cnt1,
	sna_pause_cnt2,
	sna_pause_presc0,
	sna_pause_presc1,
	sna_pause_presc2,
	sna_hsync,
	sar0_lo,
	sar0_hi,
	ppr0,
	sar0_wr,
	ppr0_wr,
	sar1_lo,
	sar1_hi,
	ppr1,
	sar1_wr,
	ppr1_wr,
	sar2_lo,
	sar2_hi,
	ppr2,
	sar2_wr,
	ppr2_wr,
	dcsr_ena,
	dcsr_ena_clr,
	dma_int_set,
	sar0_addr,
	sar1_addr,
	sar2_addr,
	ram_req,
	ram_addr,
	ram_data,
	cpu_psg_addr,
	cpu_ppi_access,
	cpu_psg_write,
	dma_load_owner,
	dma_load_busy,
	psg_bdir,
	psg_bc1,
	psg_dout,
	psg_active
);
	input wire clk;
	input wire reset;
	input wire cclk_en_p;
	input wire cclk_en_n;
	input wire hsync;
	input wire sna_load;
	input wire [11:0] sna_loop_cnt0;
	input wire [11:0] sna_loop_cnt1;
	input wire [11:0] sna_loop_cnt2;
	input wire [15:0] sna_loop_addr0;
	input wire [15:0] sna_loop_addr1;
	input wire [15:0] sna_loop_addr2;
	input wire [11:0] sna_pause_cnt0;
	input wire [11:0] sna_pause_cnt1;
	input wire [11:0] sna_pause_cnt2;
	input wire [7:0] sna_pause_presc0;
	input wire [7:0] sna_pause_presc1;
	input wire [7:0] sna_pause_presc2;
	input wire sna_hsync;
	input wire [7:0] sar0_lo;
	input wire [7:0] sar0_hi;
	input wire [7:0] ppr0;
	input wire sar0_wr;
	input wire ppr0_wr;
	input wire [7:0] sar1_lo;
	input wire [7:0] sar1_hi;
	input wire [7:0] ppr1;
	input wire sar1_wr;
	input wire ppr1_wr;
	input wire [7:0] sar2_lo;
	input wire [7:0] sar2_hi;
	input wire [7:0] ppr2;
	input wire sar2_wr;
	input wire ppr2_wr;
	input wire [2:0] dcsr_ena;
	output reg [2:0] dcsr_ena_clr;
	output reg [2:0] dma_int_set;
	output wire [15:0] sar0_addr;
	output wire [15:0] sar1_addr;
	output wire [15:0] sar2_addr;
	output reg ram_req;
	output reg [15:0] ram_addr;
	input wire [15:0] ram_data;
	input wire [7:0] cpu_psg_addr;
	input wire cpu_ppi_access;
	input wire cpu_psg_write;
	output reg dma_load_owner;
	output reg dma_load_busy;
	output reg psg_bdir;
	output reg psg_bc1;
	output reg [7:0] psg_dout;
	output reg psg_active;
	reg [15:0] sar_cur [0:2];
	reg [11:0] pause_cnt [0:2];
	reg [7:0] prescaler_cnt [0:2];
	reg [11:0] loop_cnt [0:2];
	reg [15:0] loop_addr [0:2];
	assign sar0_addr = sar_cur[0];
	assign sar1_addr = sar_cur[1];
	assign sar2_addr = sar_cur[2];
	reg hsync_d;
	wire hsync_rising = hsync && !hsync_d;
	reg [2:0] active_ch;
	reg [15:0] instr [0:2];
	localparam [4:0] ST_IDLE = 5'd0;
	localparam [4:0] ST_DEAD = 5'd1;
	localparam [4:0] ST_FETCH0 = 5'd2;
	localparam [4:0] ST_FETCH1 = 5'd3;
	localparam [4:0] ST_FETCH2 = 5'd4;
	localparam [4:0] ST_EXEC0_A = 5'd5;
	localparam [4:0] ST_EXEC0_B = 5'd6;
	localparam [4:0] ST_EXEC0_C = 5'd7;
	localparam [4:0] ST_EXEC0_D = 5'd8;
	localparam [4:0] ST_EXEC0_E = 5'd9;
	localparam [4:0] ST_EXEC0_F = 5'd10;
	localparam [4:0] ST_EXEC0_G = 5'd11;
	localparam [4:0] ST_EXEC0_H = 5'd12;
	localparam [4:0] ST_EXEC1_A = 5'd13;
	localparam [4:0] ST_EXEC1_B = 5'd14;
	localparam [4:0] ST_EXEC1_C = 5'd15;
	localparam [4:0] ST_EXEC1_D = 5'd16;
	localparam [4:0] ST_EXEC1_E = 5'd17;
	localparam [4:0] ST_EXEC1_F = 5'd18;
	localparam [4:0] ST_EXEC1_G = 5'd19;
	localparam [4:0] ST_EXEC1_H = 5'd20;
	localparam [4:0] ST_EXEC2_A = 5'd21;
	localparam [4:0] ST_EXEC2_B = 5'd22;
	localparam [4:0] ST_EXEC2_C = 5'd23;
	localparam [4:0] ST_EXEC2_D = 5'd24;
	localparam [4:0] ST_EXEC2_E = 5'd25;
	localparam [4:0] ST_EXEC2_F = 5'd26;
	localparam [4:0] ST_EXEC2_G = 5'd27;
	localparam [4:0] ST_EXEC2_H = 5'd28;
	localparam [4:0] ST_DONE = 5'd29;
	reg [4:0] state;
	reg [1:0] load_extra;
	reg load_extension;
	wire [4:0] exec_first_state = (active_ch[0] ? ST_EXEC0_A : (active_ch[1] ? ST_EXEC1_A : (active_ch[2] ? ST_EXEC2_A : ST_DONE)));
	wire [4:0] exec_after0_state = (active_ch[1] ? ST_EXEC1_A : (active_ch[2] ? ST_EXEC2_A : ST_DONE));
	wire [4:0] exec_after1_state = (active_ch[2] ? ST_EXEC2_A : ST_DONE);
	wire pause_done0 = (pause_cnt[0] == 12'd0) || ((pause_cnt[0] == 12'd1) && ((prescaler_cnt[0] == 8'd0) || ppr0_wr));
	wire pause_done1 = (pause_cnt[1] == 12'd0) || ((pause_cnt[1] == 12'd1) && ((prescaler_cnt[1] == 8'd0) || ppr1_wr));
	wire pause_done2 = (pause_cnt[2] == 12'd0) || ((pause_cnt[2] == 12'd1) && ((prescaler_cnt[2] == 8'd0) || ppr2_wr));
	integer c;
	always @(posedge clk)
		if (reset) begin
			hsync_d <= 1'b0;
			state <= ST_IDLE;
			active_ch <= 3'd0;
			dcsr_ena_clr <= 3'd0;
			dma_int_set <= 3'd0;
			ram_req <= 1'b0;
			ram_addr <= 16'd0;
			dma_load_owner <= 1'b0;
			dma_load_busy <= 1'b0;
			load_extra <= 2'd0;
			load_extension <= 1'b0;
			psg_bdir <= 1'b0;
			psg_bc1 <= 1'b0;
			psg_dout <= 8'd0;
			psg_active <= 1'b0;
			for (c = 0; c < 3; c = c + 1)
				begin
					sar_cur[c] <= 16'd0;
					pause_cnt[c] <= 12'd0;
					prescaler_cnt[c] <= 8'd0;
					loop_cnt[c] <= 12'd0;
					loop_addr[c] <= 16'd0;
					instr[c] <= 16'd0;
				end
		end
		else if (sna_load) begin
			hsync_d <= sna_hsync;
			state <= ST_IDLE;
			active_ch <= 3'd0;
			dcsr_ena_clr <= 3'd0;
			dma_int_set <= 3'd0;
			ram_req <= 1'b0;
			ram_addr <= 16'd0;
			dma_load_owner <= 1'b0;
			dma_load_busy <= 1'b0;
			load_extra <= 2'd0;
			load_extension <= 1'b0;
			psg_bdir <= 1'b0;
			psg_bc1 <= 1'b0;
			psg_dout <= 8'd0;
			psg_active <= 1'b0;
			sar_cur[0] <= {sar0_hi, sar0_lo};
			sar_cur[1] <= {sar1_hi, sar1_lo};
			sar_cur[2] <= {sar2_hi, sar2_lo};
			pause_cnt[0] <= sna_pause_cnt0;
			pause_cnt[1] <= sna_pause_cnt1;
			pause_cnt[2] <= sna_pause_cnt2;
			prescaler_cnt[0] <= sna_pause_presc0;
			prescaler_cnt[1] <= sna_pause_presc1;
			prescaler_cnt[2] <= sna_pause_presc2;
			loop_cnt[0] <= sna_loop_cnt0;
			loop_cnt[1] <= sna_loop_cnt1;
			loop_cnt[2] <= sna_loop_cnt2;
			loop_addr[0] <= sna_loop_addr0;
			loop_addr[1] <= sna_loop_addr1;
			loop_addr[2] <= sna_loop_addr2;
			instr[0] <= 16'd0;
			instr[1] <= 16'd0;
			instr[2] <= 16'd0;
		end
		else begin
			hsync_d <= hsync;
			dcsr_ena_clr <= 3'd0;
			dma_int_set <= 3'd0;
			if (sar0_wr)
				sar_cur[0] <= {sar0_hi, sar0_lo};
			if (sar1_wr)
				sar_cur[1] <= {sar1_hi, sar1_lo};
			if (sar2_wr)
				sar_cur[2] <= {sar2_hi, sar2_lo};
			if (hsync_rising) begin
				for (c = 0; c < 3; c = c + 1)
					if (dcsr_ena[c] && (pause_cnt[c] > 12'd0)) begin
						if ((prescaler_cnt[c] == 8'd0) || (c == 0 ? ppr0_wr : (c == 1 ? ppr1_wr : ppr2_wr))) begin
							prescaler_cnt[c] <= (c == 0 ? ppr0 : (c == 1 ? ppr1 : ppr2));
							pause_cnt[c] <= pause_cnt[c] - 12'd1;
						end
						else
							prescaler_cnt[c] <= prescaler_cnt[c] - 8'd1;
					end
				active_ch[0] <= dcsr_ena[0] && pause_done0;
				active_ch[1] <= dcsr_ena[1] && pause_done1;
				active_ch[2] <= dcsr_ena[2] && pause_done2;
				state <= ST_DEAD;
			end
			else begin
				if ((ppr0_wr && dcsr_ena[0]) && (pause_cnt[0] > 12'd0))
					prescaler_cnt[0] <= 8'd0;
				if ((ppr1_wr && dcsr_ena[1]) && (pause_cnt[1] > 12'd0))
					prescaler_cnt[1] <= 8'd0;
				if ((ppr2_wr && dcsr_ena[2]) && (pause_cnt[2] > 12'd0))
					prescaler_cnt[2] <= 8'd0;
				if (cclk_en_p)
					case (state)
						ST_IDLE: begin
							dma_load_owner <= 1'b0;
							dma_load_busy <= 1'b0;
							psg_active <= 1'b0;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
						end
						ST_DEAD: begin
							ram_req <= 1'b0;
							if (|active_ch) begin
								if (active_ch[0]) begin
									state <= ST_FETCH0;
									ram_req <= 1'b1;
									ram_addr <= {sar_cur[0][15:1], 1'b0};
								end
								else if (active_ch[1]) begin
									state <= ST_FETCH1;
									ram_req <= 1'b1;
									ram_addr <= {sar_cur[1][15:1], 1'b0};
								end
								else begin
									state <= ST_FETCH2;
									ram_req <= 1'b1;
									ram_addr <= {sar_cur[2][15:1], 1'b0};
								end
							end
							else
								state <= ST_IDLE;
						end
						ST_FETCH0: begin
							if (active_ch[0]) begin
								instr[0] <= ram_data;
								sar_cur[0] <= sar_cur[0] + 16'd2;
							end
							if (active_ch[1]) begin
								ram_req <= 1'b1;
								ram_addr <= {sar_cur[1][15:1], 1'b0};
								state <= ST_FETCH1;
							end
							else if (active_ch[2]) begin
								ram_req <= 1'b1;
								ram_addr <= {sar_cur[2][15:1], 1'b0};
								state <= ST_FETCH2;
							end
							else begin
								ram_req <= 1'b0;
								state <= exec_first_state;
							end
						end
						ST_FETCH1: begin
							if (active_ch[1]) begin
								instr[1] <= ram_data;
								sar_cur[1] <= sar_cur[1] + 16'd2;
							end
							if (active_ch[2]) begin
								ram_req <= 1'b1;
								ram_addr <= {sar_cur[2][15:1], 1'b0};
								state <= ST_FETCH2;
							end
							else begin
								ram_req <= 1'b0;
								state <= exec_first_state;
							end
						end
						ST_FETCH2: begin
							if (active_ch[2]) begin
								instr[2] <= ram_data;
								sar_cur[2] <= sar_cur[2] + 16'd2;
							end
							ram_req <= 1'b0;
							state <= exec_first_state;
						end
						ST_EXEC0_A:
							if (!active_ch[0])
								state <= exec_after0_state;
							else if (instr[0][14:12] == 3'b000) begin
								dma_load_owner <= 1'b1;
								dma_load_busy <= 1'b1;
								load_extra <= (cpu_psg_write ? 2'd2 : (cpu_ppi_access ? 2'd1 : 2'd0));
								load_extension <= 1'b0;
								psg_active <= 1'b1;
								psg_bdir <= 1'b1;
								psg_bc1 <= 1'b1;
								psg_dout <= {4'h0, instr[0][11:8]};
								state <= ST_EXEC0_B;
							end
							else if (((instr[0][14] && instr[0][13]) && instr[0][0]) && !instr[0][5])
								state <= exec_after0_state;
							else begin
								if (instr[0][12] && ((instr[0][11:0] != 12'd0) || instr[0][13])) begin
									pause_cnt[0] <= instr[0][11:0];
									prescaler_cnt[0] <= ppr0;
								end
								if (instr[0][13] && ((instr[0][11:0] != 12'd0) || instr[0][12])) begin
									loop_cnt[0] <= instr[0][11:0];
									loop_addr[0] <= sar_cur[0];
								end
								if (instr[0][14]) begin
									if (instr[0][5])
										dcsr_ena_clr[0] <= 1'b1;
									if (instr[0][4])
										dma_int_set[0] <= 1'b1;
									if ((instr[0][0] && !instr[0][5]) && (loop_cnt[0] != 12'd0)) begin
										sar_cur[0] <= loop_addr[0];
										loop_cnt[0] <= loop_cnt[0] - 12'd1;
									end
								end
								state <= exec_after0_state;
							end
						ST_EXEC0_B: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC0_C;
						end
						ST_EXEC0_C: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b1;
							psg_bc1 <= 1'b0;
							psg_dout <= instr[0][7:0];
							state <= ST_EXEC0_D;
						end
						ST_EXEC0_D: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC0_E;
						end
						ST_EXEC0_E: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b1;
							psg_bc1 <= 1'b1;
							psg_dout <= cpu_psg_addr;
							state <= ST_EXEC0_F;
						end
						ST_EXEC0_F: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC0_G;
						end
						ST_EXEC0_G: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC0_H;
						end
						ST_EXEC0_H:
							if (!load_extension) begin
								dma_load_owner <= 1'b0;
								psg_active <= 1'b0;
								psg_bdir <= 1'b0;
								psg_bc1 <= 1'b0;
								load_extension <= 1'b1;
								if (cpu_psg_write)
									load_extra <= 2'd2;
								else if (cpu_ppi_access && (load_extra == 2'd0))
									load_extra <= 2'd1;
								if (!cpu_ppi_access && (load_extra == 2'd0)) begin
									dma_load_busy <= 1'b0;
									state <= exec_after0_state;
								end
							end
							else if (load_extra > 2'd1)
								load_extra <= 2'd0;
							else if (cpu_psg_write && (load_extra == 2'd1))
								load_extra <= 2'd0;
							else begin
								load_extra <= 2'd0;
								dma_load_busy <= 1'b0;
								state <= exec_after0_state;
							end
						ST_EXEC1_A:
							if (!active_ch[1])
								state <= exec_after1_state;
							else if (instr[1][14:12] == 3'b000) begin
								dma_load_owner <= 1'b1;
								dma_load_busy <= 1'b1;
								load_extra <= (cpu_psg_write ? 2'd2 : (cpu_ppi_access ? 2'd1 : 2'd0));
								load_extension <= 1'b0;
								psg_active <= 1'b1;
								psg_bdir <= 1'b1;
								psg_bc1 <= 1'b1;
								psg_dout <= {4'h0, instr[1][11:8]};
								state <= ST_EXEC1_B;
							end
							else if (((instr[1][14] && instr[1][13]) && instr[1][0]) && !instr[1][5])
								state <= exec_after1_state;
							else begin
								if (instr[1][12] && ((instr[1][11:0] != 12'd0) || instr[1][13])) begin
									pause_cnt[1] <= instr[1][11:0];
									prescaler_cnt[1] <= ppr1;
								end
								if (instr[1][13] && ((instr[1][11:0] != 12'd0) || instr[1][12])) begin
									loop_cnt[1] <= instr[1][11:0];
									loop_addr[1] <= sar_cur[1];
								end
								if (instr[1][14]) begin
									if (instr[1][5])
										dcsr_ena_clr[1] <= 1'b1;
									if (instr[1][4])
										dma_int_set[1] <= 1'b1;
									if ((instr[1][0] && !instr[1][5]) && (loop_cnt[1] != 12'd0)) begin
										sar_cur[1] <= loop_addr[1];
										loop_cnt[1] <= loop_cnt[1] - 12'd1;
									end
								end
								state <= exec_after1_state;
							end
						ST_EXEC1_B: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC1_C;
						end
						ST_EXEC1_C: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b1;
							psg_bc1 <= 1'b0;
							psg_dout <= instr[1][7:0];
							state <= ST_EXEC1_D;
						end
						ST_EXEC1_D: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC1_E;
						end
						ST_EXEC1_E: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b1;
							psg_bc1 <= 1'b1;
							psg_dout <= cpu_psg_addr;
							state <= ST_EXEC1_F;
						end
						ST_EXEC1_F: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC1_G;
						end
						ST_EXEC1_G: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC1_H;
						end
						ST_EXEC1_H:
							if (!load_extension) begin
								dma_load_owner <= 1'b0;
								psg_active <= 1'b0;
								psg_bdir <= 1'b0;
								psg_bc1 <= 1'b0;
								load_extension <= 1'b1;
								if (cpu_psg_write)
									load_extra <= 2'd2;
								else if (cpu_ppi_access && (load_extra == 2'd0))
									load_extra <= 2'd1;
								if (!cpu_ppi_access && (load_extra == 2'd0)) begin
									dma_load_busy <= 1'b0;
									state <= exec_after1_state;
								end
							end
							else if (load_extra > 2'd1)
								load_extra <= 2'd0;
							else if (cpu_psg_write && (load_extra == 2'd1))
								load_extra <= 2'd0;
							else begin
								load_extra <= 2'd0;
								dma_load_busy <= 1'b0;
								state <= exec_after1_state;
							end
						ST_EXEC2_A:
							if (!active_ch[2])
								state <= ST_DONE;
							else if (instr[2][14:12] == 3'b000) begin
								dma_load_owner <= 1'b1;
								dma_load_busy <= 1'b1;
								load_extra <= (cpu_psg_write ? 2'd2 : (cpu_ppi_access ? 2'd1 : 2'd0));
								load_extension <= 1'b0;
								psg_active <= 1'b1;
								psg_bdir <= 1'b1;
								psg_bc1 <= 1'b1;
								psg_dout <= {4'h0, instr[2][11:8]};
								state <= ST_EXEC2_B;
							end
							else if (((instr[2][14] && instr[2][13]) && instr[2][0]) && !instr[2][5])
								state <= ST_DONE;
							else begin
								if (instr[2][12] && ((instr[2][11:0] != 12'd0) || instr[2][13])) begin
									pause_cnt[2] <= instr[2][11:0];
									prescaler_cnt[2] <= ppr2;
								end
								if (instr[2][13] && ((instr[2][11:0] != 12'd0) || instr[2][12])) begin
									loop_cnt[2] <= instr[2][11:0];
									loop_addr[2] <= sar_cur[2];
								end
								if (instr[2][14]) begin
									if (instr[2][5])
										dcsr_ena_clr[2] <= 1'b1;
									if (instr[2][4])
										dma_int_set[2] <= 1'b1;
									if ((instr[2][0] && !instr[2][5]) && (loop_cnt[2] != 12'd0)) begin
										sar_cur[2] <= loop_addr[2];
										loop_cnt[2] <= loop_cnt[2] - 12'd1;
									end
								end
								state <= ST_DONE;
							end
						ST_EXEC2_B: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC2_C;
						end
						ST_EXEC2_C: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b1;
							psg_bc1 <= 1'b0;
							psg_dout <= instr[2][7:0];
							state <= ST_EXEC2_D;
						end
						ST_EXEC2_D: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC2_E;
						end
						ST_EXEC2_E: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b1;
							psg_bc1 <= 1'b1;
							psg_dout <= cpu_psg_addr;
							state <= ST_EXEC2_F;
						end
						ST_EXEC2_F: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC2_G;
						end
						ST_EXEC2_G: begin
							if (cpu_psg_write)
								load_extra <= 2'd2;
							else if (cpu_ppi_access && (load_extra == 2'd0))
								load_extra <= 2'd1;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_EXEC2_H;
						end
						ST_EXEC2_H:
							if (!load_extension) begin
								dma_load_owner <= 1'b0;
								psg_active <= 1'b0;
								psg_bdir <= 1'b0;
								psg_bc1 <= 1'b0;
								load_extension <= 1'b1;
								if (cpu_psg_write)
									load_extra <= 2'd2;
								else if (cpu_ppi_access && (load_extra == 2'd0))
									load_extra <= 2'd1;
								if (!cpu_ppi_access && (load_extra == 2'd0)) begin
									dma_load_busy <= 1'b0;
									state <= ST_DONE;
								end
							end
							else if (load_extra > 2'd1)
								load_extra <= 2'd0;
							else if (cpu_psg_write && (load_extra == 2'd1))
								load_extra <= 2'd0;
							else begin
								load_extra <= 2'd0;
								dma_load_busy <= 1'b0;
								state <= ST_DONE;
							end
						ST_DONE: begin
							dma_load_owner <= 1'b0;
							dma_load_busy <= 1'b0;
							psg_active <= 1'b0;
							psg_bdir <= 1'b0;
							psg_bc1 <= 1'b0;
							state <= ST_IDLE;
						end
						default: state <= ST_IDLE;
					endcase
			end
		end
endmodule
