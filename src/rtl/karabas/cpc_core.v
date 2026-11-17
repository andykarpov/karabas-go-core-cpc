`timescale 1ns / 1ps
`default_nettype wire
/*
 cpc_core.v

 The board independent part of the CPC core (the tops of the boards put the clocks, kg_mcu2, the
 OSD, the line doubler, audio and HDMI / VGA around it; sim/ runs it in Verilator): cpc_emu (the
 machine and the upstream glue of the MiSTer core, rtl/karabas/cpc_emu.sv made by
 tools/make_cpc_emu.py) with the MiSTer hps_io outputs made from the kg_mcu2 signals:

 - loads (ld_*, link v2 target LOAD) -> the ioctl download of upstream (ld_index below: kind 0 the
   roms of the .kg = index 0, boot.rom 160K at 0; FL slots 2 Tape, 3 Snapshot, 4 ROM), the
   extension (ld_ext) as ioctl_file_ext. The bytes go through a fifo of 1K (ld_ready = 512 free:
   the mcu sends packets of 512) and leave one per 16 clocks at most while ioctl_wait is low;
   ioctl_download rises with the first byte and holds until the fifo is empty after the END.
 - the PS/2 set 2 bytes of the keyboard (ps2_*) -> ps2_key of MiSTer (bit 10 toggles per key,
   9 pressed, 8 extended, 7..0 the code)
 - the mouse (ms_*, USB: y down) -> ps2_mouse (bit 24 toggles, y up, the sign bits 4 / 5)
 - the pads (joy_l / joy_r of link v2) -> joystick_0 / 1 of MiSTer (0 right, 1 left, 2 down, 3 up,
   4..6 fire 1..3 = A, B, C)
 - the soft switches -> status (the bits of CONF_STR in upstream/Amstrad.sv); a new Model resets
 - the disk images: drives A / B of u765 on the file mounter of kg_mcu2 (slots 0 / 1, cpc_sd_sdc).
*/
module cpc_core (
	input wire clk_sys,          // 64 MHz
	input wire locked,
	input wire areset,           // synchronised to clk_sys

	// loads of kg_mcu2
	input wire [1:0] ld_kind,
	input wire [7:0] ld_slot,
	input wire [63:0] ld_ext,
	input wire ld_start,
	input wire ld_active,
	input wire ld_wr,
	input wire [31:0] ld_addr,
	input wire [7:0] ld_data,
	output wire ld_ready,

	// keyboard, mouse, pads of kg_mcu2
	input wire [7:0] ps2_code,
	input wire ps2_kind,
	input wire ps2_wr,
	input wire [7:0] ms_x,
	input wire [7:0] ms_y,
	input wire [7:0] ms_b,
	input wire ms_wr,
	input wire [15:0] joy_l,
	input wire [15:0] joy_r,

	// soft switches
	input wire [1:0] sw_model,   // 0 CPC 6128, 1 CPC 664, 2 CPC 464
	input wire sw_crtc,          // 0 type 1, 1 type 0
	input wire [2:0] sw_display, // 0 colour (GA), 1 colour (ASIC), 2 green, 3 amber, 4 cyan, 5 white
	input wire sw_reset,

	// the file mounter of kg_mcu2 (ENABLE_IMG, IMG_OUT_LATENCY 3): drives A / B = slots 0 / 1
	input wire [7:0] sdc_img_mounted,
	input wire [63:0] sdc_img_size,
	input wire [7:0] img_wp,
	output wire [7:0] sdc_rd,
	output wire [7:0] sdc_wr,
	output wire [31:0] sdc_sector,
	input wire sdc_busy,
	input wire sdc_done,
	input wire [2:0] sdc_slot,
	input wire sdc_byte_in_strobe,
	input wire [8:0] sdc_byte_addr,
	input wire [7:0] sdc_byte_in_data,
	output wire [7:0] sdc_byte_out_data,

	// SRAM
	output wire [20:0] MA,
	input wire [15:0] MD_I,
	output wire [15:0] MD_O,
	output wire MD_OE,
	output wire [1:0] MWR_N,
	output wire [1:0] MRD_N,

	// the picture at vid_ce (16 MHz), high active syncs and blanks
	output wire vid_ce,
	output wire [7:0] vid_r,
	output wire [7:0] vid_g,
	output wire [7:0] vid_b,
	output wire vid_hs,
	output wire vid_vs,
	output wire vid_hbl,
	output wire vid_vbl,

	output wire [15:0] audio_l,
	output wire [15:0] audio_r,

	input wire tape_in,
	output wire tape_out,
	output wire led_user,
	output wire loading
);

// ------------------------------------------------------------------ loads -> ioctl

// the ioctl index of upstream (CONF_STR) for a load: kind 0 (the roms of the .kg) = 0, the FL items
// by slot: 2 Tape (CDT) = 4, 3 Snapshot (SNA) = 6, 4 ROM (expansion, the page from .eXX / .eZZ /
// .eZ0) = 3; anything else is not taken
function [8:0] ld_index;   // { taken, index }
	input [1:0] kind;
	input [7:0] slot;
	begin
		ld_index = 9'd0;
		if (kind == 2'd0)
			ld_index = { 1'b1, 8'd0 };
		else if (kind == 2'd2)
			case (slot)
			8'd2: ld_index = { 1'b1, 8'd4 };
			8'd3: ld_index = { 1'b1, 8'd6 };
			8'd4: ld_index = { 1'b1, 8'd3 };
			default: ;
			endcase
	end
endfunction

// ioctl_file_ext of MiSTer: the last (up to 4) chars of the extension, upper case, the last in [7:0]
function [31:0] mister_ext;
	input [63:0] e;            // ld_ext: byte 0 = the first char, 0 padded
	integer k;
	reg [7:0] c;
	begin
		mister_ext = 32'd0;
		for (k = 0; k < 8; k = k + 1) begin
			c = e[k*8 +: 8];
			if (c != 8'd0)
				mister_ext = { mister_ext[23:0], (c >= "a" && c <= "z") ? c - 8'd32 : c };
		end
	end
endfunction

wire ioctl_wait;
wire fifo_full, fifo_empty;
wire [10:0] fifo_count;
wire [32:0] fifo_dout;
reg fifo_rd = 1'b0;

wire [8:0] ld_ix = ld_index(ld_kind, ld_slot);
reg ld_take = 1'b0;          // the open load goes to the machine
reg ld_first = 1'b0;         // its first byte has not come yet
reg [7:0] ld_idx = 8'd0;

kg_fifo #(.DW(33), .AW(10)) ld_fifo (
	.clk(clk_sys),
	.reset(areset),
	.wr(ld_wr && ld_take),
	.din({ ld_addr[24:0], ld_data }),
	.full(fifo_full),
	.rd(fifo_rd),
	.dout(fifo_dout),
	.empty(fifo_empty),
	.count(fifo_count)
);
assign ld_ready = fifo_count <= 11'd512;

reg ioctl_download = 1'b0;
reg [7:0] ioctl_index = 8'd0;
reg [31:0] ioctl_file_ext = 32'd0;
reg ioctl_wr = 1'b0;
reg [24:0] ioctl_addr = 25'd0;
reg [7:0] ioctl_dout = 8'd0;
reg [3:0] pace = 4'd0;
reg [1:0] rd_ph = 2'd0;      // 1: dout comes next clock, 2: dout valid

always @(posedge clk_sys) begin
	fifo_rd <= 1'b0;
	ioctl_wr <= 1'b0;
	if (pace != 4'd0)
		pace <= pace - 4'd1;

	if (areset) begin
		ld_take <= 1'b0;
		ld_first <= 1'b0;
		ioctl_download <= 1'b0;
		rd_ph <= 2'd0;
		pace <= 4'd0;
	end
	else begin
		// START: taken or not; the index and the extension (complete before the first DATA byte)
		// go to ioctl with that byte, ioctl_download rises then (upstream reads the extension at
		// its rising edge), two clocks before the first ioctl_wr
		if (ld_start) begin
			ld_take <= ld_ix[8];
			ld_idx <= ld_ix[7:0];
			ld_first <= 1'b1;
		end
		else if (!ld_active)
			ld_take <= 1'b0;
		if (ld_wr && ld_take && ld_first) begin
			ld_first <= 1'b0;
			ioctl_index <= ld_idx;
			ioctl_file_ext <= mister_ext(ld_ext);
			ioctl_download <= 1'b1;
		end

		case (rd_ph)
		2'd0:
			if (!fifo_empty && pace == 4'd0 && !ioctl_wait && ioctl_download) begin
				fifo_rd <= 1'b1;
				rd_ph <= 2'd1;
			end
			else if (fifo_empty && !ld_take)
				ioctl_download <= 1'b0;
		2'd1:
			rd_ph <= 2'd2;
		default: begin
			ioctl_addr <= fifo_dout[32:8];
			ioctl_dout <= fifo_dout[7:0];
			ioctl_wr <= 1'b1;
			pace <= 4'd15;
			rd_ph <= 2'd0;
		end
		endcase
	end
end
assign loading = ioctl_download;

// ------------------------------------------------------------------ keyboard: PS/2 set 2 -> ps2_key

reg [10:0] ps2_key = 11'd0;
reg ps2_ext = 1'b0, ps2_rel = 1'b0;
always @(posedge clk_sys)
	if (ps2_wr && !ps2_kind) begin
		if (ps2_code == 8'hE0)
			ps2_ext <= 1'b1;
		else if (ps2_code == 8'hF0)
			ps2_rel <= 1'b1;
		else if (ps2_code == 8'hE1 || ps2_code == 8'hFA || ps2_code == 8'hAA) begin
			ps2_ext <= 1'b0;
			ps2_rel <= 1'b0;
		end
		else begin
			ps2_key <= { ~ps2_key[10], ~ps2_rel, ps2_ext, ps2_code };
			ps2_ext <= 1'b0;
			ps2_rel <= 1'b0;
		end
	end

// ------------------------------------------------------------------ mouse -> ps2_mouse

reg [24:0] ps2_mouse = 25'd0;
wire [7:0] ms_y_up = 8'd0 - ms_y;
always @(posedge clk_sys)
	if (ms_wr)
		ps2_mouse <= { ~ps2_mouse[24], ms_y_up, ms_x, 2'b00, ms_y_up[7], ms_x[7], 1'b1, ms_b[2:0] };

// ------------------------------------------------------------------ pads

function [6:0] mister_joy;
	input [15:0] j;
	mister_joy = j[0] ? { j[8], j[7], j[6], j[1], j[2], j[3], j[4] } : 7'd0;
endfunction
wire [6:0] joy1_usb = mister_joy(joy_l);
wire [6:0] joy2_usb = mister_joy(joy_r);

// ------------------------------------------------------------------ status

// the CONF_STR bits of upstream/Amstrad.sv (only the ones with a meaning on our boards; the rest 0 =
// the upstream defaults): 0 reset, 2 CRTC (0 type 1), 5:4 model, 13:11 display, 20 tape sound,
// 30 pixel clock (0 = 16 MHz: ce_pix = ce_16 always)
// a new Model resets the machine (upstream takes the model at a reset: "Reset & apply model")
reg [1:0] model_q = 2'd0;
reg [7:0] model_rst = 8'd0;
always @(posedge clk_sys) begin
	model_q <= sw_model;
	if (model_q != sw_model)
		model_rst <= 8'hFF;
	else if (model_rst != 8'd0)
		model_rst <= model_rst - 8'd1;
end

wire [63:0] status;
assign status[0] = sw_reset | (model_rst != 8'd0);
assign status[1] = 1'b0;
assign status[2] = sw_crtc;
assign status[3] = 1'b0;
assign status[5:4] = sw_model;
assign status[10:6] = 5'd0;
assign status[13:11] = sw_display;
assign status[63:14] = 50'd0;

// ------------------------------------------------------------------ the machine

wire [31:0] sd_lba;
wire [1:0] sd_rd, sd_wr, sd_ack, img_mounted;
wire [7:0] sd_buff_din, sd_buff_dout;
wire [8:0] sd_buff_addr;
wire sd_buff_wr, img_readonly;
wire [63:0] img_size;

cpc_sd_sdc disks (
	.clk(clk_sys),
	.reset(areset),
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_size(img_size),
	.img_readonly(img_readonly),
	.sdc_img_mounted(sdc_img_mounted),
	.sdc_img_size(sdc_img_size),
	.img_wp(img_wp),
	.sdc_rd(sdc_rd),
	.sdc_wr(sdc_wr),
	.sdc_sector(sdc_sector),
	.sdc_busy(sdc_busy),
	.sdc_done(sdc_done),
	.sdc_slot(sdc_slot),
	.sdc_byte_in_strobe(sdc_byte_in_strobe),
	.sdc_byte_addr(sdc_byte_addr),
	.sdc_byte_in_data(sdc_byte_in_data),
	.sdc_byte_out_data(sdc_byte_out_data)
);

cpc_emu emu (
	.clk_sys(clk_sys),
	.locked(locked),
	.RESET(areset),

	.status(status),
	.buttons(2'b00),
	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),
	.joy1_usb(joy1_usb),
	.joy2_usb(joy2_usb),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_file_ext(ioctl_file_ext),
	.ioctl_wait(ioctl_wait),
	.img_mounted(img_mounted),
	.img_size(img_size),
	.img_readonly(img_readonly),
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.MA(MA),
	.MD_I(MD_I),
	.MD_O(MD_O),
	.MD_OE(MD_OE),
	.MWR_N(MWR_N),
	.MRD_N(MRD_N),

	.vid_ce(vid_ce),
	.vid_r(vid_r),
	.vid_g(vid_g),
	.vid_b(vid_b),
	.vid_hs(vid_hs),
	.vid_vs(vid_vs),
	.vid_hbl(vid_hbl),
	.vid_vbl(vid_vbl),

	.AUDIO_L(audio_l),
	.AUDIO_R(audio_r),

	.tape_in(tape_in),
	.tape_out(tape_out),
	.led_user(led_user)
);

endmodule
