`default_nettype wire
module u765 (
	clk_sys,
	ce,
	reset,
	ready,
	motor,
	available,
	fast,
	a0,
	nRD,
	nWR,
	din,
	dout,
	img_mounted,
	img_wp,
	img_size,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_buff_addr,
	sd_buff_dout,
	sd_buff_din,
	sd_buff_wr,
	snap_pcn_a,
	snap_pcn_b
);
	parameter CYCLES = 20'd4000;
	parameter SPECCY_SPEEDLOCK_HACK = 0;
	input clk_sys;
	input ce;
	input reset;
	input [1:0] ready;
	input [1:0] motor;
	input [1:0] available;
	input fast;
	input a0;
	input nRD;
	input nWR;
	input [7:0] din;
	output wire [7:0] dout;
	input [1:0] img_mounted;
	input img_wp;
	input [31:0] img_size;
	output reg [31:0] sd_lba;
	output reg [1:0] sd_rd;
	output reg [1:0] sd_wr;
	input sd_ack;
	input [8:0] sd_buff_addr;
	input [7:0] sd_buff_dout;
	output wire [7:0] sd_buff_din;
	input sd_buff_wr;
	output wire [7:0] snap_pcn_a;
	output wire [7:0] snap_pcn_b;
	localparam OVERRUN_TIMEOUT = CYCLES;
	localparam [19:0] TRACK_TIME = CYCLES * 8'd205;
	localparam [15:0] SECTOR_EXTRA_DATA_LEN = 61;
	localparam [15:0] SECTOR_IDAM_POS = 21;
	localparam [15:0] SECTOR_IDAM_LENGTH = 9;
	localparam [15:0] SECTOR_SYNC1_START = 0;
	localparam [15:0] SECTOR_SYNC1_END = SECTOR_SYNC1_START + 8'd12;
	localparam [15:0] SECTOR_SYNC2_START = 43;
	localparam [15:0] SECTOR_SYNC2_END = SECTOR_SYNC2_START + 8'd12;
	localparam [15:0] SECTOR_DATA_START = 60;
	localparam UPD765_MAIN_D0B = 0;
	localparam UPD765_MAIN_D1B = 1;
	localparam UPD765_MAIN_D2B = 2;
	localparam UPD765_MAIN_D3B = 3;
	localparam UPD765_MAIN_CB = 4;
	localparam UPD765_MAIN_EXM = 5;
	localparam UPD765_MAIN_DIO = 6;
	localparam UPD765_MAIN_RQM = 7;
	localparam UPD765_SD_BUFF_TRACKINFO = 1'd0;
	localparam UPD765_SD_BUFF_SECTOR = 1'd1;
	reg [7:0] buff_data_in;
	reg [7:0] buff_data_out;
	reg [7:0] tinfo_data;
	reg [8:0] buff_addr;
	reg [8:0] tinfo_addr;
	reg buff_wr;
	reg buff_wait;
	reg sd_buff_type;
	reg sd_cancel_active;
	reg sd_cancel_ack_seen;
	reg tinfo_hds;
	reg tinfo_ds0;
	reg tinfo_lock;
	reg tinfo_wait;
	reg hds;
	reg ds0;
	wire sd_accept_buff = ~reset & ~sd_cancel_active;
	wire [8:1] sv2v_tmp_tinfo_ram_q_b;
	always @(*) tinfo_data = sv2v_tmp_tinfo_ram_q_b;
	u765_dpram #(
		.DATAWIDTH(8),
		.ADDRWIDTH(11)
	) tinfo_ram(
		.clock(clk_sys),
		.address_a({tinfo_ds0, tinfo_hds, sd_buff_addr}),
		.data_a(sd_buff_dout),
		.wren_a(((sd_buff_wr & sd_ack) & sd_accept_buff) & (sd_buff_type == UPD765_SD_BUFF_TRACKINFO)),
		.q_a(),
		.address_b({tinfo_ds0, tinfo_hds, tinfo_addr}),
		.data_b(),
		.wren_b(1'b0),
		.q_b(sv2v_tmp_tinfo_ram_q_b)
	);
	wire [8:1] sv2v_tmp_sector_ram_q_b;
	always @(*) buff_data_in = sv2v_tmp_sector_ram_q_b;
	u765_dpram #(
		.DATAWIDTH(8),
		.ADDRWIDTH(9)
	) sector_ram(
		.clock(clk_sys),
		.address_a(sd_buff_addr),
		.data_a(sd_buff_dout),
		.wren_a(((sd_buff_wr & sd_ack) & sd_accept_buff) & (sd_buff_type == UPD765_SD_BUFF_SECTOR)),
		.q_a(sd_buff_din),
		.address_b(buff_addr),
		.data_b(buff_data_out),
		.wren_b(buff_wr),
		.q_b(sv2v_tmp_sector_ram_q_b)
	);
	reg [15:0] image_track_offsets [0:1023];
	reg [9:0] image_track_offsets_addr = 0;
	reg image_track_offsets_wr;
	reg [15:0] image_track_offsets_out;
	reg [15:0] image_track_offsets_in;
	always @(posedge clk_sys)
		if (image_track_offsets_wr) begin
			image_track_offsets[image_track_offsets_addr] <= image_track_offsets_out;
			image_track_offsets_in <= image_track_offsets_out;
		end
		else
			image_track_offsets_in <= image_track_offsets[image_track_offsets_addr];
	reg [5:0] ack;
	reg [1:0] sd_rd_mount;
	reg sd_busy_mount;
	reg [1:0] sd_rd_tinfo;
	reg sd_busy_tinfo;
	reg [1:0] sd_rd_sector;
	reg [1:0] sd_wr_sector;
	reg sd_busy_sector;
	reg [31:0] i_seek_pos;
	reg i_write_prev;
	wire sd_arbiter_idle = ((!sd_cancel_active & !sd_busy_mount) & !sd_busy_tinfo) & !sd_busy_sector;
	always @(posedge clk_sys) begin : sdcontrol
		if (reset && !sd_cancel_active) begin
			ack <= 0;
			if ((sd_busy_mount | sd_busy_tinfo) | sd_busy_sector) begin
				sd_cancel_active <= 1;
				sd_cancel_ack_seen <= sd_ack | (|ack);
				if (sd_ack | (|ack)) begin
					sd_rd <= 0;
					sd_wr <= 0;
				end
			end
			else begin
				sd_lba <= 0;
				sd_rd <= 0;
				sd_wr <= 0;
				sd_busy_mount <= 0;
				sd_busy_tinfo <= 0;
				sd_busy_sector <= 0;
				sd_buff_type <= UPD765_SD_BUFF_SECTOR;
				sd_cancel_active <= 0;
				sd_cancel_ack_seen <= 0;
			end
		end
		else if (sd_cancel_active) begin
			ack <= 0;
			if (sd_ack) begin
				sd_cancel_ack_seen <= 1;
				sd_rd <= 0;
				sd_wr <= 0;
			end
			if (sd_cancel_ack_seen && !sd_ack) begin
				sd_busy_mount <= 0;
				sd_busy_tinfo <= 0;
				sd_busy_sector <= 0;
				sd_cancel_active <= 0;
				sd_cancel_ack_seen <= 0;
				sd_lba <= 0;
				sd_buff_type <= UPD765_SD_BUFF_SECTOR;
			end
		end
		else begin
			ack <= {ack[4:0], sd_ack};
			if (ack[5:4] == 'b1) begin
				sd_rd <= 0;
				sd_wr <= 0;
			end
			if (ack[5:4] == 'b10) begin
				sd_busy_mount <= 0;
				sd_busy_tinfo <= 0;
				sd_busy_sector <= 0;
			end
			if (sd_arbiter_idle) begin
				if (sd_rd_mount != 2'b00) begin
					sd_lba <= 0;
					sd_rd <= sd_rd_mount;
					sd_buff_type <= UPD765_SD_BUFF_SECTOR;
					sd_busy_mount <= 1;
				end
				else if (sd_rd_tinfo != 2'b00) begin
					sd_lba <= image_track_offsets_in[15:1];
					sd_rd <= sd_rd_tinfo;
					sd_buff_type <= UPD765_SD_BUFF_TRACKINFO;
					sd_busy_tinfo <= 1;
				end
				else if (sd_rd_sector != 2'b00) begin
					sd_lba <= i_seek_pos[31:9];
					sd_rd <= sd_rd_sector;
					sd_buff_type <= UPD765_SD_BUFF_SECTOR;
					sd_busy_sector <= 1;
				end
				else if (sd_wr_sector != 2'b00) begin
					sd_lba <= i_seek_pos[31:9] - i_write_prev;
					sd_wr <= sd_wr_sector;
					sd_buff_type <= UPD765_SD_BUFF_SECTOR;
					sd_busy_sector <= 1;
				end
			end
		end
	end
	wire rd = nWR & ~nRD;
	wire wr = ~nWR & nRD;
	reg [7:0] m_status;
	reg [7:0] m_data;
	assign dout = (a0 ? m_data : m_status);
	reg [15:0] snap_pcn_r;
	assign snap_pcn_a = snap_pcn_r[8+:8];
	assign snap_pcn_b = snap_pcn_r[0+:8];
	function [15:0] SECTOR_SIZE;
		input [3:0] n;
		input [15:0] stored_size;
		reg [15:0] logical_size;
		begin
			logical_size = 16'h0080 << (n[3] ? 4'h8 : n[2:0]);
			SECTOR_SIZE = (logical_size < stored_size ? logical_size : stored_size);
		end
	endfunction
	reg [1:0] image_scan_state [0:1];
	initial begin
		image_scan_state[0] = 2'd0;
		image_scan_state[1] = 2'd0;
	end
	always @(posedge clk_sys) begin : fdc
		reg [31:0] image_size [0:1];
		reg image_ready [0:1];
		reg [7:0] image_tracks [0:1];
		reg image_sides [0:1];
		reg [1:0] image_wp;
		reg [0:1] image_trackinfo_dirty;
		reg image_edsk [0:1];
		reg [19:0] i_steptimer [0:1];
		reg [19:0] i_rpm_timer [0:1][0:1];
		reg [3:0] i_step_state [0:1];
		reg [7:0] i_byte_clk_cnt;
		reg i_byte_clk_en;
		reg [7:0] i_current_track_sectors [0:3];
		reg [15:0] i_current_sector_pos [0:1];
		reg [7:0] i_next_sector_pos [0:1][0:1];
		reg [3:0] i_secinfo_valid;
		reg [15:0] ncn;
		reg [15:0] pcn;
		reg [0:1] disk_changed;
		reg [2:0] next_weak_sector [0:1];
		reg [5:0] seek_state;
		reg [0:1] i_seek_start;
		reg [0:1] int_state;
		reg sector_search_ds0;
		reg sector_search_hds;
		reg [2:0] sector_search_state;
		reg [7:0] sector_pos [0:1][0:1];
		reg [31:0] sector_offset [0:1][0:1];
		reg [7:0] sector_c [0:1][0:1];
		reg [7:0] sector_h [0:1][0:1];
		reg [7:0] sector_r [0:1][0:1];
		reg [7:0] sector_n [0:1][0:1];
		reg [7:0] sector_st1 [0:1][0:1];
		reg [7:0] sector_st2 [0:1][0:1];
		reg [7:0] gap3 [0:1][0:1];
		reg [15:0] sector_length [0:1][0:1];
		reg [33:0] sector_byte_pos [0:1];
		reg [16:0] sector_end_pos [0:1][0:1];
		reg old_wr;
		reg old_rd;
		reg [7:0] i_track_size;
		reg [7:0] i_sector_c;
		reg [7:0] i_sector_h;
		reg [7:0] i_sector_r;
		reg [7:0] i_sector_n;
		reg [7:0] i_sector_st1;
		reg [7:0] i_sector_st2;
		reg [15:0] i_sector_size;
		reg [7:0] i_current_sector;
		reg [7:0] i_sector;
		reg i_scanning;
		reg [2:0] i_weak_sector;
		reg [15:0] i_bytes_to_read;
		reg [2:0] i_substate;
		reg [1:0] old_mounted;
		reg [15:0] i_track_offset;
		reg [19:0] i_timeout;
		reg [7:0] i_head_timer;
		reg i_rtrack;
		reg i_write;
		reg i_rw_deleted;
		reg [7:0] status [0:3];
		reg [31:0] state;
		reg [31:0] i_command;
		reg i_current_drive;
		reg i_scan_lock;
		reg [3:0] i_srt;
		reg [7:0] i_c;
		reg [7:0] i_h;
		reg [7:0] i_r;
		reg [7:0] i_n;
		reg [7:0] i_eot;
		reg [7:0] i_dtl;
		reg [7:0] i_sc;
		reg i_bc;
		reg i_mt;
		reg i_sk;
		buff_wait <= 0;
		tinfo_wait <= 0;
		snap_pcn_r <= pcn;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 2; i = i + 1)
				begin
					old_mounted[i] <= img_mounted[i];
					if (~old_mounted[i] & img_mounted[i]) begin
						image_wp[i] <= img_wp;
						image_size[i] <= img_size;
						image_scan_state[i] <= {1'b0, |img_size};
						image_ready[i] <= 0;
						disk_changed[i] <= 1;
						int_state[i] <= 0;
						seek_state[(1 - i) * 3+:3] <= 0;
						i_seek_start[i] <= 0;
						next_weak_sector[i] <= 0;
						i_current_sector_pos[i] <= 16'h0000;
						i_secinfo_valid[(1 - i) * 2+:2] <= 2'h0;
					end
				end
		end
		if (ce) begin
			i_current_drive <= ~i_current_drive;
			if (i_current_drive) begin
				i_byte_clk_cnt <= i_byte_clk_cnt + 1'd1;
				i_byte_clk_en <= 0;
				if (i_byte_clk_cnt == (((CYCLES * 32) / 1000) - 1)) begin
					i_byte_clk_cnt <= 0;
					i_byte_clk_en <= 1;
				end
			end
		end
		if (ce)
			case (image_scan_state[i_current_drive])
				0:
					;
				1:
					if ((sd_arbiter_idle & !i_scan_lock) & (state == 32'd0)) begin
						i_scan_lock <= 1;
						sd_rd_mount[i_current_drive] <= 1;
						i_track_offset <= 16'h0001;
						image_track_offsets_addr <= {i_current_drive, 9'd0};
						buff_addr <= 0;
						buff_wait <= 1;
						image_scan_state[i_current_drive] <= 2;
					end
				2:
					if (!sd_busy_mount & (sd_rd_mount == 2'b00)) begin
						if (!buff_wait) begin
							if (buff_addr == 0) begin
								if (buff_data_in == "E")
									image_edsk[i_current_drive] <= 1;
								else if (buff_data_in == "M")
									image_edsk[i_current_drive] <= 0;
								else begin
									image_ready[i_current_drive] <= 0;
									image_scan_state[i_current_drive] <= 0;
									i_scan_lock <= 0;
								end
							end
							else if (buff_addr == 9'h030)
								image_tracks[i_current_drive] <= buff_data_in;
							else if (buff_addr == 9'h031)
								image_sides[i_current_drive] <= buff_data_in[1];
							else if (buff_addr == 9'h033)
								i_track_size <= buff_data_in;
							else if (buff_addr >= 9'h034) begin
								if (image_track_offsets_addr[8:1] != image_tracks[i_current_drive]) begin
									image_track_offsets_wr <= 1;
									if (image_edsk[i_current_drive]) begin
										image_track_offsets_out <= (buff_data_in ? i_track_offset : 16'd0);
										i_track_offset <= i_track_offset + buff_data_in;
									end
									else begin
										image_track_offsets_out <= i_track_offset;
										i_track_offset <= i_track_offset + i_track_size;
									end
									image_scan_state[i_current_drive] <= 3;
								end
								else begin
									image_ready[i_current_drive] <= 1;
									image_scan_state[i_current_drive] <= 0;
									image_trackinfo_dirty[i_current_drive] <= 1;
									i_scan_lock <= 0;
								end
							end
							buff_addr <= buff_addr + 1'd1;
							buff_wait <= 1;
						end
					end
					else
						sd_rd_mount <= 0;
				3: begin
					image_track_offsets_wr <= 0;
					image_track_offsets_addr <= image_track_offsets_addr + {~image_sides[i_current_drive], image_sides[i_current_drive]};
					image_scan_state[i_current_drive] <= 2;
				end
			endcase
		if (reset) begin
			sd_rd_mount <= 0;
			sd_rd_tinfo <= 0;
			sd_rd_sector <= 0;
			sd_wr_sector <= 0;
			m_status <= 8'h80;
			state <= 32'd0;
			status[0] <= 0;
			status[1] <= 0;
			status[2] <= 0;
			ncn <= 16'h0000;
			pcn <= 16'h0000;
			int_state <= 2'h0;
			seek_state <= 6'h00;
			i_seek_start <= 2'h0;
			disk_changed <= 2'h0;
			image_trackinfo_dirty <= 2'h3;
			i_secinfo_valid <= 4'h0;
			image_track_offsets_wr <= 0;
			if (image_scan_state[0])
				image_scan_state[0] <= 1;
			if (image_scan_state[1])
				image_scan_state[1] <= 1;
			i_scan_lock <= 0;
			i_srt <= 4;
			tinfo_lock <= 0;
		end
		else if (ce) begin
			old_wr <= wr;
			old_rd <= rd;
			case (seek_state[(1 - i_current_drive) * 3+:3])
				0:
					if (i_seek_start[i_current_drive]) begin
						seek_state[(1 - i_current_drive) * 3+:3] <= 1;
						i_seek_start[i_current_drive] <= 0;
					end
					else if ((image_trackinfo_dirty[i_current_drive] && image_ready[i_current_drive]) && !tinfo_lock)
						seek_state[(1 - i_current_drive) * 3+:3] <= 3;
				1:
					if (pcn[(1 - i_current_drive) * 8+:8] == ncn[(1 - i_current_drive) * 8+:8]) begin
						int_state[i_current_drive] <= 1;
						seek_state[(1 - i_current_drive) * 3+:3] <= 0;
					end
					else begin
						image_trackinfo_dirty[i_current_drive] <= 1;
						if (fast)
							pcn[(1 - i_current_drive) * 8+:8] <= ncn[(1 - i_current_drive) * 8+:8];
						else begin
							if (pcn[(1 - i_current_drive) * 8+:8] > ncn[(1 - i_current_drive) * 8+:8])
								pcn[(1 - i_current_drive) * 8+:8] <= pcn[(1 - i_current_drive) * 8+:8] - 1'd1;
							if (pcn[(1 - i_current_drive) * 8+:8] < ncn[(1 - i_current_drive) * 8+:8])
								pcn[(1 - i_current_drive) * 8+:8] <= pcn[(1 - i_current_drive) * 8+:8] + 1'd1;
							i_step_state[i_current_drive] <= i_srt;
							i_steptimer[i_current_drive] <= CYCLES;
							seek_state[(1 - i_current_drive) * 3+:3] <= 2;
						end
					end
				2:
					if (i_steptimer[i_current_drive])
						i_steptimer[i_current_drive] <= i_steptimer[i_current_drive] - 1'd1;
					else if (~&i_step_state[i_current_drive]) begin
						i_step_state[i_current_drive] <= i_step_state[i_current_drive] + 1'd1;
						i_steptimer[i_current_drive] <= CYCLES;
					end
					else
						seek_state[(1 - i_current_drive) * 3+:3] <= 1;
				3: begin
					$display("reload trackinfo: drive %d track %d", i_current_drive, pcn[(1 - i_current_drive) * 8+:8]);
					if (!tinfo_lock) begin
						sector_byte_pos[i_current_drive] <= 34'h000000000;
						i_current_track_sectors[{i_current_drive, 1'b0}] <= 0;
						i_current_track_sectors[{i_current_drive, 1'b1}] <= 0;
						next_weak_sector[i_current_drive] <= 0;
						image_track_offsets_addr <= {i_current_drive, pcn[(1 - i_current_drive) * 8+:8], 1'b0};
						tinfo_ds0 <= i_current_drive;
						tinfo_hds <= 0;
						tinfo_wait <= 1;
						seek_state[(1 - i_current_drive) * 3+:3] <= 4;
						tinfo_lock <= 1;
					end
				end
				4:
					if (sd_arbiter_idle & !tinfo_wait) begin
						if (image_ready[i_current_drive] && image_track_offsets_in) begin
							sd_rd_tinfo[i_current_drive] <= 1;
							seek_state[(1 - i_current_drive) * 3+:3] <= 5;
						end
						else begin
							$display("reload trackinfo: empty track");
							i_current_track_sectors[{i_current_drive, tinfo_hds}] <= 0;
							tinfo_lock <= 0;
							image_trackinfo_dirty[i_current_drive] <= 0;
							seek_state[(1 - i_current_drive) * 3+:3] <= 0;
						end
					end
				5:
					if (sd_arbiter_idle & (sd_rd_tinfo == 2'b00)) begin
						tinfo_addr <= {image_track_offsets_in[0], 8'h16};
						tinfo_wait <= 1;
						seek_state[(1 - i_current_drive) * 3+:3] <= 6;
					end
					else
						sd_rd_tinfo <= 0;
				6:
					if (!tinfo_wait) begin
						gap3[i_current_drive][tinfo_hds] <= tinfo_data;
						tinfo_addr <= {image_track_offsets_in[0], 8'h15};
						tinfo_wait <= 1;
						seek_state[(1 - i_current_drive) * 3+:3] <= 7;
						i_secinfo_valid[((1 - i_current_drive) * 2) + (1 - tinfo_hds)] <= 0;
					end
				7:
					if (!tinfo_wait) begin
						i_current_track_sectors[{i_current_drive, tinfo_hds}] <= tinfo_data;
						if (i_current_sector_pos[i_current_drive][(1 - tinfo_hds) * 8+:8] >= tinfo_data) begin
							i_next_sector_pos[i_current_drive][tinfo_hds] <= 0;
							i_rpm_timer[i_current_drive][tinfo_hds] <= 0;
						end
						else
							i_next_sector_pos[i_current_drive][tinfo_hds] <= i_current_sector_pos[i_current_drive][(1 - tinfo_hds) * 8+:8];
						if (tinfo_hds == image_sides[i_current_drive]) begin
							tinfo_lock <= 0;
							image_trackinfo_dirty[i_current_drive] <= 0;
							seek_state[(1 - i_current_drive) * 3+:3] <= 0;
						end
						else begin
							image_track_offsets_addr <= {i_current_drive, pcn[(1 - i_current_drive) * 8+:8], 1'b1};
							tinfo_hds <= 1;
							tinfo_wait <= 1;
							seek_state[(1 - i_current_drive) * 3+:3] <= 4;
						end
					end
			endcase
			case (sector_search_state)
				0:
					if (!i_secinfo_valid[3] && image_ready[0]) begin
						{sector_search_ds0, sector_search_hds} <= 2'b00;
						sector_search_state <= 1;
					end
					else if (!i_secinfo_valid[2] && image_ready[0]) begin
						{sector_search_ds0, sector_search_hds} <= 2'b01;
						sector_search_state <= 1;
					end
					else if (!i_secinfo_valid[1] && image_ready[1]) begin
						{sector_search_ds0, sector_search_hds} <= 2'b10;
						sector_search_state <= 1;
					end
					else if (!i_secinfo_valid[0] && image_ready[1]) begin
						{sector_search_ds0, sector_search_hds} <= 2'b11;
						sector_search_state <= 1;
					end
				1:
					if (!image_trackinfo_dirty[sector_search_ds0] && !tinfo_lock) begin
						tinfo_lock <= 1;
						image_track_offsets_addr <= {sector_search_ds0, pcn[(1 - sector_search_ds0) * 8+:8], sector_search_hds};
						tinfo_wait <= 1;
						sector_search_state <= 2;
					end
				2:
					if (~tinfo_wait) begin
						i_current_sector <= 0;
						sector_offset[sector_search_ds0][sector_search_hds] <= {image_track_offsets_in + (i_current_track_sectors[{sector_search_ds0, sector_search_hds}] > 29 ? 2'd2 : 2'd1), 8'd0};
						tinfo_addr <= {image_track_offsets_in[0], 8'h14};
						tinfo_hds <= sector_search_hds;
						tinfo_ds0 <= sector_search_ds0;
						tinfo_wait <= 1;
						sector_search_state <= 3;
					end
				3:
					if (~tinfo_wait) begin
						if (tinfo_addr[7:0] == 8'h14) begin
							if (!image_edsk[sector_search_ds0])
								sector_length[sector_search_ds0][sector_search_hds] <= 16'h0080 << tinfo_data[2:0];
							tinfo_addr[7:0] <= 8'h18;
							tinfo_wait <= 1;
						end
						else if ((i_current_sector == 8'h1d) && ~tinfo_addr[0]) begin
							sector_r[sector_search_ds0][sector_search_hds] <= sector_r[sector_search_ds0][sector_search_hds] + 1'd1;
							sector_n[sector_search_ds0][sector_search_hds] <= 8'h02;
							sector_length[sector_search_ds0][sector_search_hds] <= 16'h0200;
							sector_st1[sector_search_ds0][sector_search_hds] <= 0;
							sector_st2[sector_search_ds0][sector_search_hds] <= 0;
							sector_search_state <= 4;
						end
						else begin
							case (tinfo_addr[2:0])
								0: sector_c[sector_search_ds0][sector_search_hds] <= tinfo_data;
								1: sector_h[sector_search_ds0][sector_search_hds] <= tinfo_data;
								2: sector_r[sector_search_ds0][sector_search_hds] <= tinfo_data;
								3: sector_n[sector_search_ds0][sector_search_hds] <= tinfo_data;
								4: sector_st1[sector_search_ds0][sector_search_hds] <= tinfo_data;
								5: sector_st2[sector_search_ds0][sector_search_hds] <= tinfo_data;
								6:
									if (image_edsk[sector_search_ds0])
										sector_length[sector_search_ds0][sector_search_hds][7:0] <= tinfo_data;
								7: begin
									if (image_edsk[ds0])
										sector_length[sector_search_ds0][sector_search_hds][15:8] <= tinfo_data;
									sector_search_state <= 4;
								end
							endcase
							tinfo_addr <= tinfo_addr + 1'd1;
							tinfo_wait <= 1;
						end
					end
				4:
					if (i_current_sector == i_next_sector_pos[sector_search_ds0][sector_search_hds]) begin
						tinfo_lock <= 0;
						i_secinfo_valid[((1 - sector_search_ds0) * 2) + (1 - sector_search_hds)] <= 1;
						i_current_sector_pos[sector_search_ds0][(1 - sector_search_hds) * 8+:8] <= i_next_sector_pos[sector_search_ds0][sector_search_hds];
						sector_end_pos[sector_search_ds0][sector_search_hds] <= (SECTOR_SIZE(sector_n[sector_search_ds0][sector_search_hds], sector_length[sector_search_ds0][sector_search_hds]) + SECTOR_EXTRA_DATA_LEN) - 1;
						sector_search_state <= 0;
					end
					else if (i_current_sector == (i_current_track_sectors[{sector_search_ds0, sector_search_hds}] - 1)) begin
						$display("sector no. %d not found!", i_next_sector_pos[sector_search_ds0][sector_search_hds]);
						i_secinfo_valid[((1 - sector_search_ds0) * 2) + (1 - sector_search_hds)] <= 1;
						i_current_sector_pos[sector_search_ds0][(1 - sector_search_hds) * 8+:8] <= i_next_sector_pos[sector_search_ds0][sector_search_hds];
						sector_end_pos[sector_search_ds0][sector_search_hds] <= 0;
						tinfo_lock <= 0;
						sector_search_state <= 0;
					end
					else begin
						sector_offset[sector_search_ds0][sector_search_hds] <= sector_offset[sector_search_ds0][sector_search_hds] + sector_length[sector_search_ds0][sector_search_hds];
						i_current_sector <= i_current_sector + 1'd1;
						sector_search_state <= 3;
					end
			endcase
			if (motor[i_current_drive]) begin : sv2v_autoblock_2
				reg signed [31:0] i;
				for (i = 0; i < 2; i = i + 1)
					begin
						if (i_secinfo_valid[((1 - i_current_drive) * 2) + (1 - i)])
							i_rpm_timer[i_current_drive][i] <= i_rpm_timer[i_current_drive][i] + 1'd1;
						if (i_secinfo_valid[((1 - i_current_drive) * 2) + (1 - i)] & i_byte_clk_en) begin
							sector_byte_pos[i_current_drive][(1 - i) * 17+:17] <= sector_byte_pos[i_current_drive][(1 - i) * 17+:17] + 1'd1;
							if (sector_byte_pos[i_current_drive][(1 - i) * 17+:17] >= (sector_end_pos[i_current_drive][i] + gap3[i_current_drive][i])) begin
								if ((i_current_sector_pos[i_current_drive][(1 - i) * 8+:8] == (i_current_track_sectors[{i_current_drive, i[0]}] - 1'd1)) || (i_current_track_sectors[{i_current_drive, i[0]}] == 0)) begin
									if (i_rpm_timer[i_current_drive][i] >= TRACK_TIME) begin
										i_next_sector_pos[i_current_drive][i] <= 0;
										sector_byte_pos[i_current_drive][(1 - i) * 17+:17] <= 0;
										i_secinfo_valid[((1 - i_current_drive) * 2) + (1 - i)] <= 0;
										i_rpm_timer[i_current_drive][i] <= 0;
									end
								end
								else begin
									i_next_sector_pos[i_current_drive][i] <= i_current_sector_pos[i_current_drive][(1 - i) * 8+:8] + 1'd1;
									sector_byte_pos[i_current_drive][(1 - i) * 17+:17] <= 0;
									i_secinfo_valid[((1 - i_current_drive) * 2) + (1 - i)] <= 0;
								end
							end
						end
					end
			end
			m_status[UPD765_MAIN_D0B] <= (seek_state[3+:3] == 1) | (seek_state[3+:3] == 2);
			m_status[UPD765_MAIN_D1B] <= (seek_state[0+:3] == 1) | (seek_state[3+:3] == 2);
			m_status[UPD765_MAIN_CB] <= state != 32'd0;
			case (state)
				32'd0: begin
					m_status[UPD765_MAIN_DIO] <= 0;
					m_status[UPD765_MAIN_RQM] <= !image_scan_state[0] & !image_scan_state[1];
					if ((((~old_wr & wr) & a0) & !image_scan_state[0]) & !image_scan_state[1]) begin
						i_mt <= din[7];
						i_sk <= din[5];
						i_substate <= 0;
						casez (din[7:0])
							8'bzzz00110: state <= 32'd5;
							8'bzzz01100: state <= 32'd4;
							8'bzz000101: state <= 32'd3;
							8'bzz001001: state <= 32'd2;
							8'b0zz00010: state <= 32'd1;
							8'b0z001010: state <= 32'd16;
							8'b0z001101: state <= 32'd19;
							8'bzzz10001: state <= 32'd28;
							8'bzzz11001: state <= 32'd29;
							8'bzzz11101: state <= 32'd30;
							8'b00000111: state <= 32'd31;
							8'b00001000: state <= 32'd32;
							8'b00000011: state <= 32'd35;
							8'b00000100: state <= 32'd37;
							8'b00001111: state <= 32'd39;
							default: state <= 32'd43;
						endcase
					end
					else if ((~old_rd & rd) & a0)
						m_data <= 8'hff;
				end
				32'd32: begin
					m_status[UPD765_MAIN_DIO] <= 1;
					state <= 32'd33;
				end
				32'd33:
					if ((~old_rd & rd) & a0) begin
						if (int_state[0]) begin
							m_data <= (((ncn[8+:8] == pcn[8+:8]) && ready[0]) && image_ready[0] ? 8'h20 : 8'he8);
							state <= 32'd34;
						end
						else if (int_state[1]) begin
							m_data <= (((ncn[0+:8] == pcn[0+:8]) && ready[1]) && image_ready[1] ? 8'h21 : 8'he9);
							state <= 32'd34;
						end
						else begin
							m_data <= 8'h80;
							state <= 32'd0;
						end
					end
				32'd34:
					if ((~old_rd & rd) & a0) begin
						m_data <= (int_state[0] ? pcn[8+:8] : pcn[0+:8]);
						int_state[(int_state[0] ? 0 : 1)] <= 0;
						state <= 32'd0;
					end
				32'd37: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0) begin
						state <= 32'd38;
						m_status[UPD765_MAIN_DIO] <= 1;
						ds0 <= din[0];
					end
				end
				32'd38:
					if ((~old_rd & rd) & a0) begin
						m_data <= {1'b0, (ready[ds0] & image_wp[ds0]) | disk_changed[ds0], available[ds0], image_ready[ds0] & !pcn[(1 - ds0) * 8+:8], image_ready[ds0] & image_sides[ds0], image_ready[ds0] & hds, 1'b0, ds0};
						disk_changed[ds0] <= 0;
						state <= 32'd0;
					end
				32'd35: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0) begin
						i_srt <= din[7:4];
						state <= 32'd36;
					end
				end
				32'd36:
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				32'd31:
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						int_state[din[0]] <= 0;
						ncn[(1 - din[0]) * 8+:8] <= 0;
						i_seek_start[din[0]] <= 1;
						state <= 32'd0;
					end
				32'd39:
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						int_state[din[0]] <= 0;
						state <= 32'd40;
					end
				32'd40:
					if ((~old_wr & wr) & a0) begin
						ncn[(1 - ds0) * 8+:8] <= din;
						if ((((motor[ds0] && ready[ds0]) && image_ready[ds0]) && (din < image_tracks[ds0])) || !din)
							i_seek_start[ds0] <= 1;
						else
							int_state[ds0] <= 1;
						state <= 32'd0;
					end
				32'd16: begin
					int_state <= 2'h0;
					state <= 32'd17;
				end
				32'd17:
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						if ((~motor[din[0]] | ~ready[din[0]]) | ~image_ready[din[0]]) begin
							status[0] <= 8'h40;
							status[1] <= 8'b00000101;
							status[2] <= 0;
							state <= 32'd42;
						end
						else if (din[2] & ~image_sides[din[0]]) begin
							status[0] <= 8'h48;
							status[1] <= 0;
							status[2] <= 0;
							state <= 32'd42;
						end
						else begin
							hds <= din[2];
							m_status[UPD765_MAIN_RQM] <= 0;
							state <= 32'd18;
						end
					end
				32'd18:
					if (!image_trackinfo_dirty[ds0] & i_byte_clk_en) begin
						if ((sector_byte_pos[ds0][(1 - hds) * 17+:17] == SECTOR_SYNC1_END) || (sector_byte_pos[ds0][(1 - hds) * 17+:17] == (SECTOR_SYNC2_END + 1))) begin
							m_status[UPD765_MAIN_EXM] <= 1;
							m_status[UPD765_MAIN_DIO] <= 1;
						end
						if (i_current_track_sectors[{ds0, hds}] == 0) begin
							i_sector_c <= pcn[(1 - ds0) * 8+:8];
							i_sector_h <= {7'd0, hds};
							i_sector_r <= 8'h00;
							i_sector_n <= 8'h00;
							status[0] <= 8'h40;
							status[1] <= 8'b00000101;
							status[2] <= 0;
							state <= 32'd42;
						end
						else if ((sector_byte_pos[ds0][(1 - hds) * 17+:17] == (SECTOR_IDAM_POS + SECTOR_IDAM_LENGTH)) && i_secinfo_valid[((1 - ds0) * 2) + (1 - hds)]) begin
							i_sector_c <= sector_c[ds0][hds];
							i_sector_h <= sector_h[ds0][hds];
							i_sector_r <= sector_r[ds0][hds];
							i_sector_n <= sector_n[ds0][hds];
							status[0] <= 0;
							status[1] <= 0;
							status[2] <= 0;
							state <= 32'd42;
						end
					end
				32'd1: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd41;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b100;
				end
				32'd3: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd41;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b010;
				end
				32'd2: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd41;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b011;
				end
				32'd5: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd41;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b000;
				end
				32'd4: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd41;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b001;
				end
				32'd6:
					if (i_write & image_wp[ds0]) begin
						status[0] <= 8'h40;
						status[1] <= 8'h02;
						status[2] <= 0;
						state <= 32'd42;
					end
					else begin
						m_status[UPD765_MAIN_RQM] <= 0;
						state <= 32'd7;
					end
				32'd7:
					if (!image_trackinfo_dirty[ds0] && !tinfo_lock) begin
						m_status[UPD765_MAIN_DIO] <= ~i_write;
						if (i_rtrack)
							i_r <= 0;
						if (i_current_track_sectors[{ds0, hds}] == 0) begin
							i_sector_c <= i_c;
							i_sector_h <= i_h;
							i_sector_r <= i_r;
							i_sector_n <= i_n;
							status[0] <= 8'h40;
							status[1] <= 8'h05;
							status[2] <= 8'h00;
							state <= 32'd42;
						end
						else begin
							i_bc <= 1;
							state <= 32'd8;
						end
					end
				32'd8:
					if (i_secinfo_valid[((1 - ds0) * 2) + (1 - hds)]) begin
						i_scanning <= 0;
						i_sector <= i_current_sector_pos[ds0][(1 - hds) * 8+:8];
						state <= 32'd9;
					end
				32'd9:
					if (i_secinfo_valid[((1 - ds0) * 2) + (1 - hds)] && i_byte_clk_en) begin
						i_sector <= i_current_sector_pos[ds0][(1 - hds) * 8+:8];
						if (i_sector != i_current_sector_pos[ds0][(1 - hds) * 8+:8])
							$display("checking sector %d - C: %d H: %d R: %d N: %d ST1: %d ST2: %d length: %d", i_current_sector_pos[ds0][(1 - hds) * 8+:8], sector_c[ds0][hds], sector_h[ds0][hds], sector_r[ds0][hds], sector_n[ds0][hds], sector_st1[ds0][hds], sector_st2[ds0][hds], sector_length[ds0][hds]);
						if (((i_current_sector_pos[ds0][(1 - hds) * 8+:8] == (i_current_track_sectors[{ds0, hds}] - 1)) && (sector_byte_pos[ds0][(1 - hds) * 17+:17] == ((sector_end_pos[ds0][hds] + gap3[ds0][hds]) - 1))) && (ds0 == i_current_drive)) begin
							$display("passed index mark, pass: %d", i_scanning);
							if (i_scanning) begin
								status[0] <= (i_rtrack ? 8'h00 : 8'h40);
								status[1] <= (i_rtrack ? 8'h00 : 8'h04);
								status[2] <= (i_rtrack | ~i_bc ? 8'h00 : (sector_c[ds0][hds] == 8'hff ? 8'h02 : 8'h10));
								state <= 32'd42;
							end
							else
								i_scanning <= 1;
						end
						else if (sector_byte_pos[ds0][(1 - hds) * 17+:17] == (SECTOR_IDAM_POS + SECTOR_IDAM_LENGTH)) begin
							i_sector_c <= sector_c[ds0][hds];
							i_sector_h <= sector_h[ds0][hds];
							i_sector_r <= sector_r[ds0][hds];
							i_sector_n <= sector_n[ds0][hds];
							i_sector_st1 <= sector_st1[ds0][hds];
							i_sector_st2 <= sector_st2[ds0][hds];
							i_sector_size <= sector_length[ds0][hds];
							i_seek_pos <= sector_offset[ds0][hds];
							state <= 32'd10;
						end
					end
				32'd10:
					if ((i_rtrack && (i_current_sector_pos[ds0][(1 - hds) * 8+:8] == i_r)) || ((((~i_rtrack && (i_sector_c == i_c)) && (i_sector_r == i_r)) && (i_sector_h == i_h)) && ((i_sector_n == i_n) || !i_n))) begin
						if ((i_sk & ~i_rtrack) & (i_rw_deleted ^ i_sector_st2[6]))
							state <= 32'd15;
						else begin
							$display("sector found r/R : %d/%d pos: %d", i_r, i_sector_r, sector_byte_pos[ds0][(1 - hds) * 17+:17]);
							i_bytes_to_read <= (i_n ? SECTOR_SIZE(i_n, 16'hffff) : i_dtl);
							i_timeout <= OVERRUN_TIMEOUT;
							m_status[UPD765_MAIN_EXM] <= 1;
							i_weak_sector <= 0;
							state <= 32'd12;
						end
					end
					else begin
						if (i_sector_c == i_c)
							i_bc <= 0;
						state <= 32'd9;
					end
				32'd12:
					if (image_edsk[ds0] && (((i_sector_size == {i_bytes_to_read, 1'b0}) || (i_sector_size == ({i_bytes_to_read, 1'b0} + i_bytes_to_read))) || (i_sector_size == {i_bytes_to_read, 2'b00}))) begin
						if (i_weak_sector != next_weak_sector[ds0]) begin
							i_seek_pos <= i_seek_pos + i_bytes_to_read;
							i_sector_size <= i_sector_size - i_bytes_to_read;
							i_weak_sector <= i_weak_sector + 1'd1;
						end
						else begin
							next_weak_sector[ds0] <= next_weak_sector[ds0] + 1'd1;
							state <= 32'd11;
						end
					end
					else begin
						if (((((SPECCY_SPEEDLOCK_HACK & (i_sector == 2)) & !pcn[(1 - ds0) * 8+:8]) & ~hds) & i_sector_st1[5]) & i_sector_st2[5])
							next_weak_sector[ds0] <= next_weak_sector[ds0] + 1'd1;
						else
							next_weak_sector[ds0] <= 0;
						state <= 32'd11;
					end
				32'd11:
					if ((!sd_busy_sector & (sd_rd_sector == 2'b00)) & (sd_wr_sector == 2'b00)) begin
						sd_rd_sector[ds0] <= 1;
						buff_addr <= i_seek_pos[8:0];
						buff_wait <= 1;
						state <= 32'd13;
					end
					else begin
						sd_rd_sector <= 0;
						sd_wr_sector <= 0;
					end
				32'd13:
					if ((!sd_busy_sector & (sd_rd_sector == 2'b00)) & (sd_wr_sector == 2'b00)) begin
						if (!i_bytes_to_read) begin
							if ((i_write && buff_addr) && (i_seek_pos < image_size[ds0])) begin
								i_write_prev <= 0;
								sd_wr_sector[ds0] <= 1;
							end
							state <= 32'd15;
						end
						else if (!i_timeout) begin
							status[0] <= 8'h40;
							status[1] <= 8'h10;
							status[2] <= i_sector_st2 | (i_rw_deleted ? 8'h40 : 8'h00);
							state <= 32'd42;
						end
						else if (~m_status[UPD765_MAIN_RQM])
							m_status[UPD765_MAIN_RQM] <= 1;
						else if ((((~i_write & ~old_rd) & rd) & a0) & ~buff_wait) begin
							if (&buff_addr)
								state <= 32'd11;
							m_data <= ((((((SPECCY_SPEEDLOCK_HACK & (i_sector == 2)) & !pcn[(1 - ds0) * 8+:8]) & ~hds) & i_sector_st1[5]) & i_sector_st2[5]) & !i_bytes_to_read[14:4] ? buff_data_in << next_weak_sector[ds0] : buff_data_in);
							m_status[UPD765_MAIN_RQM] <= 0;
							if (i_sector_size) begin
								i_sector_size <= i_sector_size - 1'd1;
								buff_addr <= buff_addr + 1'd1;
								buff_wait <= 1;
								i_seek_pos <= i_seek_pos + 1'd1;
							end
							i_bytes_to_read <= i_bytes_to_read - 1'd1;
							i_timeout <= OVERRUN_TIMEOUT;
						end
						else if (((i_write & ~old_wr) & wr) & a0) begin
							buff_wr <= 1;
							buff_data_out <= din;
							i_timeout <= OVERRUN_TIMEOUT;
							m_status[UPD765_MAIN_RQM] <= 0;
							state <= 32'd14;
						end
						else
							i_timeout <= i_timeout - 1'd1;
					end
					else begin
						sd_rd_sector <= 0;
						sd_wr_sector <= 0;
					end
				32'd14: begin
					buff_wr <= 0;
					if (i_sector_size) begin
						i_sector_size <= i_sector_size - 1'd1;
						buff_addr <= buff_addr + 1'd1;
						buff_wait <= 1;
						i_seek_pos <= i_seek_pos + 1'd1;
					end
					i_bytes_to_read <= i_bytes_to_read - 1'd1;
					if (&buff_addr) begin
						if (i_seek_pos < image_size[ds0]) begin
							i_write_prev <= 1;
							sd_wr_sector[ds0] <= 1;
						end
						state <= 32'd11;
					end
					else
						state <= 32'd13;
				end
				32'd15:
					if (((!sd_busy_sector && (sd_rd_sector == 2'b00)) && (sd_wr_sector == 2'b00)) && (sector_byte_pos[ds0][(1 - hds) * 17+:17] >= (sector_end_pos[ds0][hds] + (gap3[ds0][hds] >> 2)))) begin
						if ((~i_rtrack & ~(i_sk & (i_rw_deleted ^ i_sector_st2[6]))) & ((i_sector_st1[5] & i_sector_st2[5]) | (i_rw_deleted ^ i_sector_st2[6]))) begin
							status[0] <= 8'h40;
							status[1] <= i_sector_st1;
							status[2] <= i_sector_st2 | (i_rw_deleted ? 8'h40 : 8'h00);
							state <= 32'd42;
						end
						else if ((i_rtrack ? i_sector : i_sector_r) == i_eot) begin
							status[0] <= (i_rtrack ? 8'h00 : 8'h40);
							status[1] <= 8'h80;
							status[2] <= (i_rw_deleted ^ i_sector_st2[6] ? 8'h40 : 8'h00);
							state <= 32'd42;
						end
						else begin
							if (i_mt & image_sides[ds0]) begin
								hds <= ~hds;
								i_h <= ~i_h;
							end
							if ((~i_mt | hds) | ~image_sides[ds0])
								i_r <= i_r + 1'd1;
							state <= 32'd8;
						end
					end
					else begin
						sd_rd_sector <= 0;
						sd_wr_sector <= 0;
					end
				32'd19: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						state <= 32'd20;
					end
				end
				32'd20:
					if ((~old_wr & wr) & a0) begin
						i_n <= din;
						state <= 32'd21;
					end
				32'd21:
					if ((~old_wr & wr) & a0) begin
						i_sc <= din;
						state <= 32'd22;
					end
				32'd22:
					if ((~old_wr & wr) & a0)
						state <= 32'd23;
				32'd23:
					if ((~old_wr & wr) & a0) begin
						m_status[UPD765_MAIN_EXM] <= 1;
						state <= 32'd24;
					end
				32'd24:
					if (!i_sc) begin
						status[0] <= 0;
						status[1] <= 0;
						status[2] <= 0;
						state <= 32'd42;
					end
					else if ((~old_wr & wr) & a0) begin
						i_c <= din;
						state <= 32'd25;
					end
				32'd25:
					if ((~old_wr & wr) & a0) begin
						i_h <= din;
						state <= 32'd26;
					end
				32'd26:
					if ((~old_wr & wr) & a0) begin
						i_r <= din;
						state <= 32'd27;
					end
				32'd27:
					if ((~old_wr & wr) & a0) begin
						i_n <= din;
						i_sc <= i_sc - 1'd1;
						i_r <= i_r + 1'd1;
						state <= 32'd24;
					end
				32'd28: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				end
				32'd30: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				end
				32'd29: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				end
				32'd41:
					if ((!old_wr & wr) & a0)
						case (i_substate)
							0: begin
								ds0 <= din[0];
								hds <= din[2];
								i_substate <= 1;
							end
							1: begin
								i_c <= din;
								i_substate <= 2;
							end
							2: begin
								i_h <= din;
								i_substate <= 3;
							end
							3: begin
								i_r <= din;
								i_substate <= 4;
							end
							4: begin
								i_n <= din;
								i_substate <= 5;
							end
							5: begin
								i_eot <= din;
								i_substate <= 6;
							end
							6: i_substate <= 7;
							7: begin
								i_dtl <= din;
								i_substate <= 0;
								if ((~motor[ds0] | ~ready[ds0]) | ~image_ready[ds0]) begin
									status[0] <= 8'h40;
									status[1] <= 8'b00000101;
									status[2] <= 0;
									state <= 32'd42;
								end
								else if (hds & ~image_sides[ds0]) begin
									hds <= 0;
									status[0] <= 8'h48;
									status[1] <= 0;
									status[2] <= 0;
									state <= 32'd42;
								end
								else
									state <= i_command;
							end
						endcase
				32'd42: begin
					m_status[UPD765_MAIN_RQM] <= 1;
					m_status[UPD765_MAIN_DIO] <= 1;
					m_status[UPD765_MAIN_EXM] <= 0;
					if ((~old_rd & rd) & a0)
						case (i_substate)
							0: begin
								m_data <= {status[0][7:3], hds, 1'b0, ds0};
								i_substate <= 1;
							end
							1: begin
								m_data <= status[1];
								i_substate <= 2;
							end
							2: begin
								m_data <= status[2];
								i_substate <= 3;
							end
							3: begin
								m_data <= i_sector_c;
								i_substate <= 4;
							end
							4: begin
								m_data <= i_sector_h;
								i_substate <= 5;
							end
							5: begin
								m_data <= i_sector_r;
								i_substate <= 6;
							end
							6: begin
								m_data <= i_sector_n;
								state <= 32'd0;
							end
							7:
								;
						endcase
				end
				32'd43: begin
					int_state <= 2'h0;
					m_status[UPD765_MAIN_DIO] <= 1;
					status[0] <= 8'h80;
					state <= 32'd44;
				end
				32'd44:
					if ((~old_rd & rd) & a0) begin
						state <= 32'd0;
						m_data <= status[0];
					end
			endcase
		end
	end
endmodule
