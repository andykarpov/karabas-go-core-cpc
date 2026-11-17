module joydb (
	USER_IN,
	snac_player,
	joystick1,
	joystick2,
	joystick1_en,
	joystick2_en
);
	input wire [6:0] USER_IN;
	input wire [1:0] snac_player;
	output wire [15:0] joystick1;
	output wire [15:0] joystick2;
	output wire joystick1_en;
	output wire joystick2_en;
	wire fire2 = ~USER_IN[4];
	wire fire1 = ~USER_IN[2];
	wire up = ~USER_IN[1];
	wire down = ~USER_IN[0];
	wire left = ~USER_IN[5];
	wire right = ~USER_IN[3];
	wire [15:0] joystick;
	assign joystick[15:11] = 5'd0;
	assign joystick[10] = 1'b0;
	assign joystick[9:7] = 3'd0;
	assign joystick[6] = fire2;
	assign joystick[5] = 1'b0;
	assign joystick[4] = fire1;
	assign joystick[3] = up;
	assign joystick[2] = down;
	assign joystick[1] = left;
	assign joystick[0] = right;
	assign joystick1 = (joystick1_en ? joystick : 16'd0);
	assign joystick2 = (joystick2_en ? joystick : 16'd0);
	assign joystick1_en = snac_player == 2'd1;
	assign joystick2_en = snac_player == 2'd2;
endmodule
