`default_nettype wire
module cpc_sd_sdc (
	clk,
	reset,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_buff_addr,
	sd_buff_dout,
	sd_buff_din,
	sd_buff_wr,
	img_mounted,
	img_size,
	img_readonly,
	sdc_img_mounted,
	sdc_img_size,
	img_wp,
	sdc_rd,
	sdc_wr,
	sdc_sector,
	sdc_busy,
	sdc_done,
	sdc_slot,
	sdc_byte_in_strobe,
	sdc_byte_addr,
	sdc_byte_in_data,
	sdc_byte_out_data
);
	input wire clk;
	input wire reset;
	input wire [31:0] sd_lba;
	input wire [1:0] sd_rd;
	input wire [1:0] sd_wr;
	output wire [1:0] sd_ack;
	output wire [8:0] sd_buff_addr;
	output wire [7:0] sd_buff_dout;
	input wire [7:0] sd_buff_din;
	output wire sd_buff_wr;
	output reg [1:0] img_mounted = 2'b00;
	output reg [63:0] img_size = 64'd0;
	output reg img_readonly = 1'b0;
	input wire [7:0] sdc_img_mounted;
	input wire [63:0] sdc_img_size;
	input wire [7:0] img_wp;
	output wire [7:0] sdc_rd;
	output wire [7:0] sdc_wr;
	output wire [31:0] sdc_sector;
	input wire sdc_busy;
	input wire sdc_done;
	input wire [2:0] sdc_slot;
	input wire sdc_byte_in_strobe;
	input wire [8:0] sdc_byte_addr;
	input wire [7:0] sdc_byte_in_data;
	output reg [7:0] sdc_byte_out_data = 8'd0;
	reg [1:0] act = 2'b00;
	wire mine = sdc_slot[2:1] == 2'b00;
	always @(posedge clk)
		if (reset)
			act <= 2'b00;
		else begin
			if ((sdc_busy && mine) && (act == 2'b00))
				act[sdc_slot[0]] <= 1'b1;
			if (sdc_done && mine)
				act[sdc_slot[0]] <= 1'b0;
		end
	assign sdc_rd = {6'd0, (sd_rd & ~act) & ~{2 {sdc_busy && mine}}};
	assign sdc_wr = {6'd0, (sd_wr & ~act) & ~{2 {sdc_busy && mine}}};
	assign sdc_sector = sd_lba;
	assign sd_ack = act;
	assign sd_buff_addr = sdc_byte_addr;
	assign sd_buff_dout = sdc_byte_in_data;
	assign sd_buff_wr = sdc_byte_in_strobe && (act != 2'b00);
	always @(posedge clk) sdc_byte_out_data <= sd_buff_din;
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
