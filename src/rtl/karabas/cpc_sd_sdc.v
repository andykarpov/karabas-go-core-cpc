`timescale 1ns / 1ps
`default_nettype wire
/*
 cpc_sd_sdc.v

 The sector interface of the MiSTer hps_io (what u765 talks: sd_rd / sd_wr held until sd_ack rises,
 the transfer while sd_ack is high, its end when sd_ack falls; sd_buff_* the bytes of the 512-byte
 sector) on the file mounter of kg_mcu2 (kg_l2_img, the sdc_* signals of img_sdc). Slots 0 and 1 of
 the mounter = drives A and B of u765 (F items 0 and 1 of core.json).

 - a request: sdc_rd / sdc_wr[n] = sd_rd / sd_wr[n] until the mounter takes it (sdc_busy with
   sdc_slot n): sd_ack is high from then until sdc_done of that slot;
 - read: the bytes of the mounter (sdc_byte_in_strobe / addr / data) are sd_buff_wr / addr / dout;
 - write: the mounter copies the sector by sdc_byte_addr and takes sdc_byte_out_data OUT_LATENCY
   (kg_mcu2 IMG_OUT_LATENCY = 2) clocks later: sd_buff_addr is the address, sd_buff_din comes from
   the dual port RAM of u765 a clock later and is registered here once more;
 - mount: sdc_img_mounted[n] (one clock, sdc_img_size, img_wp[n]) = img_mounted[n] with img_size and
   img_readonly.
*/
module cpc_sd_sdc (
	input wire clk,
	input wire reset,

	// u765 (MiSTer hps_io side)
	input wire [31:0] sd_lba,
	input wire [1:0] sd_rd,
	input wire [1:0] sd_wr,
	output wire [1:0] sd_ack,
	output wire [8:0] sd_buff_addr,
	output wire [7:0] sd_buff_dout,
	input wire [7:0] sd_buff_din,
	output wire sd_buff_wr,
	output reg [1:0] img_mounted = 2'b00,
	output reg [63:0] img_size = 64'd0,
	output reg img_readonly = 1'b0,

	// kg_mcu2 file mounter
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
	output reg [7:0] sdc_byte_out_data = 8'd0
);

reg [1:0] act = 2'b00;      // the request of drive n is taken, until its sdc_done
wire mine = sdc_slot[2:1] == 2'b00;

always @(posedge clk) begin
	if (reset)
		act <= 2'b00;
	else begin
		if (sdc_busy && mine && act == 2'b00)
			act[sdc_slot[0]] <= 1'b1;
		if (sdc_done && mine)
			act[sdc_slot[0]] <= 1'b0;
	end
end

assign sdc_rd = { 6'd0, sd_rd & ~act & ~{ 2{ sdc_busy && mine } } };
assign sdc_wr = { 6'd0, sd_wr & ~act & ~{ 2{ sdc_busy && mine } } };
assign sdc_sector = sd_lba;
assign sd_ack = act;

assign sd_buff_addr = sdc_byte_addr;
assign sd_buff_dout = sdc_byte_in_data;
assign sd_buff_wr = sdc_byte_in_strobe && act != 2'b00;

always @(posedge clk)
	sdc_byte_out_data <= sd_buff_din;

always @(posedge clk) begin
	img_mounted <= sdc_img_mounted[1:0];
	if (sdc_img_mounted[0]) begin
		img_size <= sdc_img_size;
		img_readonly <= img_wp[0];
	end
	else if (sdc_img_mounted[1]) begin
		img_size <= sdc_img_size;
		img_readonly <= img_wp[1];
	end
end

endmodule
