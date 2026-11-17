module hps_io (
	clk_sys,
	HPS_BUS,
	joystick_0,
	joystick_1,
	ps2_key,
	ps2_mouse,
	buttons,
	forced_scandoubler,
	gamma_bus,
	status,
	status_in,
	status_set,
	status_menumask,
	info_req,
	info,
	img_mounted,
	img_readonly,
	img_size,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_buff_addr,
	sd_buff_dout,
	sd_buff_din,
	sd_buff_wr,
	ioctl_download,
	ioctl_index,
	ioctl_wr,
	ioctl_addr,
	ioctl_dout,
	ioctl_file_ext,
	ioctl_wait
);
	parameter CONF_STR = "";
	parameter CONF_STR_BRAM = 0;
	parameter PS2DIV = 0;
	parameter WIDE = 0;
	parameter VDNUM = 1;
	parameter BLKSZ = 2;
	parameter PS2WE = 0;
	parameter STRLEN = 1;
	parameter F12KEYMOD = 0;
	input clk_sys;
	inout [45:0] HPS_BUS;
	output wire [31:0] joystick_0;
	output wire [31:0] joystick_1;
	output wire [10:0] ps2_key;
	output wire [24:0] ps2_mouse;
	output wire [1:0] buttons;
	output wire forced_scandoubler;
	inout [21:0] gamma_bus;
	output wire [127:0] status;
	input [127:0] status_in;
	input status_set;
	input [15:0] status_menumask;
	input info_req;
	input [7:0] info;
	output wire [VDNUM - 1:0] img_mounted;
	output wire img_readonly;
	output wire [63:0] img_size;
	input [(VDNUM * 32) - 1:0] sd_lba;
	input [VDNUM - 1:0] sd_rd;
	input [VDNUM - 1:0] sd_wr;
	output wire [VDNUM - 1:0] sd_ack;
	output wire [13:0] sd_buff_addr;
	output wire [7:0] sd_buff_dout;
	input [(VDNUM * 8) - 1:0] sd_buff_din;
	output wire sd_buff_wr;
	output wire ioctl_download;
	output wire [15:0] ioctl_index;
	output wire ioctl_wr;
	output wire [26:0] ioctl_addr;
	output wire [7:0] ioctl_dout;
	output wire [31:0] ioctl_file_ext;
	input ioctl_wait;
	localparam N = (((231 + VDNUM) + 65) + VDNUM) + 108;
	reg [N - 1:0] sr;
	always @(posedge clk_sys) sr <= {sr[N - 2:0], HPS_BUS[0]};
	assign {joystick_0, joystick_1, ps2_key, ps2_mouse, buttons, forced_scandoubler, status, img_mounted, img_readonly, img_size, sd_ack, sd_buff_addr, sd_buff_dout, sd_buff_wr, ioctl_download, ioctl_index, ioctl_wr, ioctl_addr, ioctl_dout, ioctl_file_ext} = sr;
	integer i;
	reg fold;
	always @(posedge clk_sys) begin
		fold = ((((((^status_in ^ status_set) ^ ^status_menumask) ^ info_req) ^ ^info) ^ ^sd_rd) ^ ^sd_wr) ^ ioctl_wait;
		for (i = 0; i < VDNUM; i = i + 1)
			fold = (fold ^ ^sd_lba[((VDNUM - 1) - i) * 32+:32]) ^ ^sd_buff_din[((VDNUM - 1) - i) * 8+:8];
	end
	assign HPS_BUS[1] = fold;
	assign HPS_BUS[45:2] = 1'sbz;
	assign gamma_bus = 1'sbz;
endmodule
