module altddio_out (
	datain_h,
	datain_l,
	outclock,
	dataout,
	aclr,
	aset,
	oe,
	outclocken,
	sclr,
	sset
);
	parameter extend_oe_disable = "OFF";
	parameter intended_device_family = "";
	parameter invert_output = "OFF";
	parameter lpm_hint = "";
	parameter lpm_type = "";
	parameter oe_reg = "";
	parameter power_up_high = "OFF";
	parameter width = 1;
	input [width - 1:0] datain_h;
	input [width - 1:0] datain_l;
	input outclock;
	output wire [width - 1:0] dataout;
	input aclr;
	input aset;
	input oe;
	input outclocken;
	input sclr;
	input sset;
	assign dataout = (outclock ? datain_h : datain_l);
endmodule
