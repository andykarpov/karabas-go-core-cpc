`default_nettype wire
module amstrad_video_color (
	CLK_VIDEO,
	ce_16,
	hq2x,
	pixel_rate_select,
	plus_mode,
	pixel_vblank,
	mode,
	mix,
	r4,
	g4,
	b4,
	hs,
	vs,
	hbl,
	vbl,
	ce_pix,
	R_out,
	G_out,
	B_out,
	HSync,
	VSync,
	HBlank,
	VBlank
);
	input CLK_VIDEO;
	input ce_16;
	input hq2x;
	input pixel_rate_select;
	input plus_mode;
	input pixel_vblank;
	input [1:0] mode;
	input [2:0] mix;
	input [3:0] r4;
	input [3:0] g4;
	input [3:0] b4;
	input hs;
	input vs;
	input hbl;
	input vbl;
	output wire ce_pix;
	output wire [7:0] R_out;
	output wire [7:0] G_out;
	output wire [7:0] B_out;
	output wire HSync;
	output wire VSync;
	output wire HBlank;
	output wire VBlank;
	reg ce_pix_fs;
	always @(posedge CLK_VIDEO) begin : sv2v_autoblock_1
		reg [1:0] mode_fs;
		reg [1:0] mode_next;
		reg [1:0] cycle;
		reg old_vsync;
		ce_pix_fs <= 0;
		if (ce_16) begin
			cycle <= cycle + 1'd1;
			case (mode_fs)
				2: ce_pix_fs <= 1;
				1: ce_pix_fs <= !cycle[0];
				0, 3: ce_pix_fs <= !cycle[1:0];
			endcase
			old_vsync <= vs;
			if (~old_vsync & vs) begin
				mode_fs <= mode_next;
				mode_next <= 0;
				cycle <= 0;
			end
			if (((~hbl && ~vbl) && ~&mode) && (mode > mode_next))
				mode_next <= mode;
		end
	end
	assign ce_pix = (hq2x | pixel_rate_select ? ce_pix_fs : ce_16);
	wire [7:0] B;
	wire [7:0] G;
	wire [7:0] R;
	color_mix color_mix(
		.clk_vid(CLK_VIDEO),
		.ce_pix(ce_pix),
		.mix(mix),
		.HSync_in(hs),
		.VSync_in(vs),
		.HBlank_in(hbl),
		.VBlank_in(vbl),
		.B_in(b4[1:0]),
		.G_in(g4[1:0]),
		.R_in(r4[1:0]),
		.HSync_out(HSync),
		.VSync_out(VSync),
		.HBlank_out(HBlank),
		.VBlank_out(VBlank),
		.B_out(B),
		.G_out(G),
		.R_out(R)
	);
	wire [7:0] R_plus_raw = {r4[3:0], r4[3:0]};
	wire [7:0] G_plus_raw = {g4[3:0], g4[3:0]};
	wire [7:0] B_plus_raw = {b4[3:0], b4[3:0]};
	wire [15:0] px_plus = ((R_plus_raw * 16'd59) + (G_plus_raw * 16'd177)) + (B_plus_raw * 16'd20);
	wire [7:0] y_plus = px_plus[15:8];
	reg [7:0] R_plus;
	reg [7:0] G_plus;
	reg [7:0] B_plus;
	always @(*)
		case (mix)
			3'd0, 3'd1: {R_plus, G_plus, B_plus} = {R_plus_raw, G_plus_raw, B_plus_raw};
			3'd2: {R_plus, G_plus, B_plus} = {8'd0, y_plus, 8'd0};
			3'd3: {R_plus, G_plus, B_plus} = {y_plus, y_plus - px_plus[15:10], 8'd0};
			3'd4: {R_plus, G_plus, B_plus} = {8'd0, y_plus, y_plus};
			3'd5: {R_plus, G_plus, B_plus} = {y_plus, y_plus, y_plus};
			default: {R_plus, G_plus, B_plus} = {R_plus_raw, G_plus_raw, B_plus_raw};
		endcase
	reg [23:0] plus_rgb;
	always @(posedge CLK_VIDEO)
		if (ce_pix)
			plus_rgb <= {R_plus, G_plus, B_plus};
	reg vbl_mask;
	always @(posedge CLK_VIDEO)
		if (ce_pix)
			vbl_mask <= pixel_vblank;
	assign R_out = (vbl_mask ? 8'd0 : (plus_mode ? plus_rgb[23:16] : R));
	assign G_out = (vbl_mask ? 8'd0 : (plus_mode ? plus_rgb[15:8] : G));
	assign B_out = (vbl_mask ? 8'd0 : (plus_mode ? plus_rgb[7:0] : B));
endmodule
