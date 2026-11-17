`default_nettype wire
module plus_menu_capability_mask (
	en270p,
	plus_mode,
	plus_has_fdc,
	plus_has_tape,
	status_menumask
);
	input en270p;
	input plus_mode;
	input plus_has_fdc;
	input plus_has_tape;
	output wire [15:0] status_menumask;
	assign status_menumask = {10'b0000000000, !plus_mode || plus_has_tape, !plus_mode || plus_has_fdc, !plus_mode, plus_mode, en270p, 1'b0};
endmodule
