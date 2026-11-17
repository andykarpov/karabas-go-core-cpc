`default_nettype wire
module hid (
	reset,
	clk,
	ps2_key,
	ps2_mouse,
	right_shift_mod,
	keypad_mod,
	joystick1,
	joystick2,
	Y,
	X,
	key_nmi,
	key_reset,
	Fn
);
	input reset;
	input clk;
	input [10:0] ps2_key;
	input [24:0] ps2_mouse;
	input right_shift_mod;
	input keypad_mod;
	input [6:0] joystick1;
	input [6:0] joystick2;
	input [3:0] Y;
	output wire [7:0] X;
	output reg key_nmi;
	output reg key_reset;
	output reg [9:0] Fn;
	wire row9 = Y == 9;
	wire row6 = Y == 6;
	wire [6:0] joy1 = (row9 ? {joystick1[6:4], joystick1[0], joystick1[1], joystick1[2], joystick1[3]} : 7'd0);
	wire [6:0] joy2 = (row6 ? {joystick2[6:4], joystick2[0], joystick2[1], joystick2[2], joystick2[3]} : 7'd0);
	reg [127:0] key = {16 {8'd0}};
	reg [2:0] mbtn = 0;
	wire [3:0] mdir;
	wire [6:0] mouse = (row9 ? {mbtn, mdir} : 7'd0);
	assign X = ~(((key[(15 - Y) * 8+:8] | joy1) | joy2) | mouse);
	wire press = ps2_key[9];
	reg alt = 0;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg old_flg;
		reg old_reset;
		old_flg <= ps2_key[10];
		old_reset <= reset;
		if (old_reset & ~reset) begin
			key <= {16 {8'd0}};
			Fn <= 0;
		end
		if (old_flg ^ ps2_key[10]) begin
			if (ps2_key[8])
				case (ps2_key[7:0])
					8'h75: key[120] <= press;
					8'h74: key[121] <= press;
					8'h72: key[122] <= press;
					8'h69: key[126] <= press;
					8'h7a: key[127] <= press;
					8'h6b: key[112] <= press;
					8'h70: key[113] <= press;
					8'h71: key[104] <= press;
					8'h5a: key[106] <= press;
					8'h14: key[111] <= press;
					8'h4a: key[102] <= press;
				endcase
			else
				case (ps2_key[7:0])
					8'h11: alt <= press;
					8'h75:
						if (keypad_mod)
							key[120] <= press;
						else
							key[115] <= press;
					8'h74:
						if (keypad_mod)
							key[121] <= press;
						else
							key[124] <= press;
					8'h72:
						if (keypad_mod)
							key[122] <= press;
						else
							key[118] <= press;
					8'h7d: key[123] <= press;
					8'h01: key[123] <= press & ~alt;
					8'h0b: key[124] <= press & ~alt;
					8'h04: key[125] <= press & ~alt;
					8'h69:
						if (keypad_mod)
							key[126] <= press;
						else
							key[117] <= press;
					8'h7a:
						if (keypad_mod)
							key[127] <= press;
						else
							key[125] <= press;
					8'h6b:
						if (keypad_mod)
							key[112] <= press;
						else
							key[108] <= press;
					8'h70:
						if (keypad_mod)
							key[113] <= press;
						else
							key[119] <= press;
					8'h73:
						if (keypad_mod)
							key[113] <= press;
						else
							key[116] <= press;
					8'h6c: key[114] <= press;
					8'h83: key[114] <= press & ~alt;
					8'h0a: key[115] <= press & ~alt;
					8'h03: key[116] <= press & ~alt;
					8'h05: key[117] <= press & ~alt;
					8'h06: key[118] <= press & ~alt;
					8'h09: key[119] <= press & ~alt;
					8'h71:
						if (keypad_mod)
							key[104] <= press;
						else
							key[103] <= press;
					8'h5b: key[105] <= press;
					8'h5a: key[106] <= press;
					8'h5d: key[107] <= press;
					8'h0c: key[108] <= press & ~alt;
					8'h12: key[109] <= press;
					8'h59:
						if (right_shift_mod)
							key[109] <= press;
						else
							key[110] <= press;
					8'h61: key[110] <= press;
					8'h14: key[111] <= press;
					8'h55: key[96] <= press;
					8'h7b: key[97] <= press;
					8'h4e: key[97] <= press;
					8'h54: key[98] <= press;
					8'h4d: key[99] <= press;
					8'h79: begin
						key[100] <= press;
						key[109] <= press;
					end
					8'h52: key[100] <= press;
					8'h7c: begin
						key[101] <= press;
						key[109] <= press;
					end
					8'h4c: key[101] <= press;
					8'h4a: key[102] <= press;
					8'h49: key[103] <= press;
					8'h45: key[88] <= press;
					8'h46: key[89] <= press;
					8'h44: key[90] <= press;
					8'h43: key[91] <= press;
					8'h4b: key[92] <= press;
					8'h42: key[93] <= press;
					8'h3a: key[94] <= press;
					8'h41: key[95] <= press;
					8'h3e: key[80] <= press;
					8'h3d: key[81] <= press;
					8'h3c: key[82] <= press;
					8'h35: key[83] <= press;
					8'h33: key[84] <= press;
					8'h3b: key[85] <= press;
					8'h31: key[86] <= press;
					8'h29: key[87] <= press;
					8'h36: key[72] <= press;
					8'h2e: key[73] <= press;
					8'h2d: key[74] <= press;
					8'h2c: key[75] <= press;
					8'h34: key[76] <= press;
					8'h2b: key[77] <= press;
					8'h32: key[78] <= press;
					8'h2a: key[79] <= press;
					8'h25: key[64] <= press;
					8'h26: key[65] <= press;
					8'h24: key[66] <= press;
					8'h1d: key[67] <= press;
					8'h1b: key[68] <= press;
					8'h23: key[69] <= press;
					8'h21: key[70] <= press;
					8'h22: key[71] <= press;
					8'h16: key[56] <= press;
					8'h1e: key[57] <= press;
					8'h76: key[58] <= press;
					8'h15: key[59] <= press;
					8'h0d: key[60] <= press;
					8'h1c: key[61] <= press;
					8'h58: key[62] <= press;
					8'h1a: key[63] <= press;
					8'h66: key[55] <= press;
					8'h78:
						if (press) begin
							key_nmi <= !alt;
							key_reset <= alt;
						end
						else begin
							key_nmi <= 0;
							key_reset <= 0;
						end
				endcase
			case (ps2_key[7:0])
				8'h05: Fn[1] <= press & alt;
				8'h06: Fn[2] <= press & alt;
				8'h04: Fn[3] <= press & alt;
				8'h0c: Fn[4] <= press & alt;
				8'h03: Fn[5] <= press & alt;
				8'h0b: Fn[6] <= press & alt;
				8'h83: Fn[7] <= press & alt;
				8'h0a: Fn[8] <= press & alt;
				8'h01: Fn[9] <= press & alt;
				8'h09: Fn[0] <= press & alt;
			endcase
		end
	end
	reg mstb = 0;
	mouse_axis mx(
		.clk(clk),
		.set(mstb),
		.offset({ps2_mouse[4], ps2_mouse[15:8]}),
		.reset(~row9),
		.dir({mdir[2], mdir[3]})
	);
	mouse_axis my(
		.clk(clk),
		.set(mstb),
		.offset({ps2_mouse[5], ps2_mouse[23:16]}),
		.reset(~row9),
		.dir({mdir[1], mdir[0]})
	);
	always @(posedge clk) begin : sv2v_autoblock_2
		reg old_status;
		old_status <= ps2_mouse[24];
		mstb <= 0;
		if (old_status != ps2_mouse[24]) begin
			mstb <= 1;
			mbtn <= ps2_mouse[2:0];
		end
	end
endmodule
