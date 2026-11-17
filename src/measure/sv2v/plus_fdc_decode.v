module plus_fdc_decode (
	addr,
	plus_mode,
	plus_has_fdc,
	fdc_disabled,
	motor_sel,
	u765_sel
);
	input [15:0] addr;
	input plus_mode;
	input plus_has_fdc;
	input fdc_disabled;
	output wire motor_sel;
	output wire u765_sel;
	wire fdc_present = !plus_mode | plus_has_fdc;
	wire classic_motor_sel = (!addr[10] & !addr[8]) & !addr[7];
	wire classic_u765_sel = (!addr[10] & addr[8]) & !addr[7];
	wire plus_motor_sel = (!addr[10] & addr[9]) & !addr[8];
	wire plus_u765_sel = ((!addr[10] & addr[9]) & addr[8]) & addr[4];
	assign motor_sel = fdc_present & (plus_mode ? plus_motor_sel : classic_motor_sel);
	assign u765_sel = (fdc_present & ~fdc_disabled) & (plus_mode ? plus_u765_sel : classic_u765_sel);
endmodule
