`timescale 1ns / 1ps
`default_nettype wire
/*
 cpc_core.v

 The board independent part of the CPC core (the tops of the boards put the clocks, kg_mcu2, the
 OSD, the line doubler, audio and HDMI / VGA around it; sim/ runs it in Verilator): cpc_emu (the
 machine and the upstream glue of the MiSTer core, rtl/karabas/cpc_emu.sv made by
 tools/make_cpc_emu.py) with the MiSTer hps_io outputs made from the kg_mcu2 signals:

 - loads (ld_*, link v2 target LOAD) -> the ioctl download of upstream: kind 0 (the roms of the
   .kg: boot.rom, 160K, at 0) = index 0 (the system ROMs of the three models); FL items later
   (Ф2). The bytes go through a fifo of 1K (ld_ready = 512 free: the mcu sends packets of 512)
   and leave one per 16 clocks at most while ioctl_wait is low; ioctl_download holds until the
   fifo is empty after the end of the load.
 - the PS/2 set 2 bytes of the keyboard (ps2_*) -> ps2_key of MiSTer (bit 10 toggles per key,
   9 pressed, 8 extended, 7..0 the code)
 - the mouse (ms_*, USB: y down) -> ps2_mouse (bit 24 toggles, y up, the sign bits 4 / 5)
 - the pads (joy_l / joy_r of link v2) -> joystick_0 / 1 of MiSTer (0 right, 1 left, 2 down, 3 up,
   4..6 fire 1..3 = A, B, C)
 - the soft switches -> status (the bits of CONF_STR in upstream/Amstrad.sv); a new Model resets
 - the disk images: not yet (Ф2), sd_ack 0.
*/
module cpc_core (
	input wire clk_sys,          // 64 MHz
	input wire locked,
	input wire areset,           // synchronised to clk_sys

	// loads of kg_mcu2
	input wire [1:0] ld_kind,
	input wire [7:0] ld_slot,
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

wire ioctl_wait;
wire fifo_full, fifo_empty;
wire [10:0] fifo_count;
wire [32:0] fifo_dout;
reg fifo_rd = 1'b0;

kg_fifo #(.DW(33), .AW(10)) ld_fifo (
	.clk(clk_sys),
	.reset(areset),
	.wr(ld_wr && ld_kind == 2'd0),
	.din({ ld_addr[24:0], ld_data }),
	.full(fifo_full),
	.rd(fifo_rd),
	.dout(fifo_dout),
	.empty(fifo_empty),
	.count(fifo_count)
);
assign ld_ready = fifo_count <= 11'd512;

reg ld_on = 1'b0;            // a ROM load is open (until its END)
reg ioctl_download = 1'b0;
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
		ld_on <= 1'b0;
		ioctl_download <= 1'b0;
		rd_ph <= 2'd0;
		pace <= 4'd0;
	end
	else begin
		if (ld_active && ld_kind == 2'd0) begin
			ld_on <= 1'b1;
			ioctl_download <= 1'b1;
		end
		else
			ld_on <= 1'b0;

		case (rd_ph)
		2'd0:
			if (!fifo_empty && pace == 4'd0 && !ioctl_wait) begin
				fifo_rd <= 1'b1;
				rd_ph <= 2'd1;
			end
			else if (fifo_empty && !ld_on && !(ld_active && ld_kind == 2'd0))
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
wire [1:0] sd_rd, sd_wr;
wire [7:0] sd_buff_din;

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
	.ioctl_index(8'd0),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_file_ext(32'd0),
	.ioctl_wait(ioctl_wait),
	.img_mounted(2'b00),
	.img_size(64'd0),
	.img_readonly(1'b0),
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(2'b00),
	.sd_buff_addr(9'd0),
	.sd_buff_dout(8'd0),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(1'b0),

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
