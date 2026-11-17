`default_nettype wire
module color_mix (
	clk_vid,
	ce_pix,
	mix,
	R_in,
	G_in,
	B_in,
	HSync_in,
	VSync_in,
	HBlank_in,
	VBlank_in,
	R_out,
	G_out,
	B_out,
	HSync_out,
	VSync_out,
	HBlank_out,
	VBlank_out
);
	input clk_vid;
	input ce_pix;
	input [2:0] mix;
	input [1:0] R_in;
	input [1:0] G_in;
	input [1:0] B_in;
	input HSync_in;
	input VSync_in;
	input HBlank_in;
	input VBlank_in;
	output reg [7:0] R_out;
	output reg [7:0] G_out;
	output reg [7:0] B_out;
	output reg HSync_out;
	output reg VSync_out;
	output reg HBlank_out;
	output reg VBlank_out;
	reg [23:0] rgb;
	always @(*)
		casex ({mix[0], R_in, G_in, B_in})
			7'b0000000: rgb = 24'h000201;
			7'b0000001: rgb = 24'h00026b;
			7'b0000010: rgb = 24'h0c02f4;
			7'b0x10000: rgb = 24'h6c0201;
			7'b0x100x1: rgb = 24'h690268;
			7'b0x10010: rgb = 24'h6c02f2;
			7'b0100000: rgb = 24'hf30506;
			7'b01000x1: rgb = 24'hf00268;
			7'b0100010: rgb = 24'hf302f4;
			7'b000x100: rgb = 24'h027801;
			7'b000x1x1: rgb = 24'h007868;
			7'b000x110: rgb = 24'h0c7bf4;
			7'b0x1x100: rgb = 24'h6e7b01;
			7'b0x1x1x1: rgb = 24'h6e7d6b;
			7'b0x1x110: rgb = 24'h6e7bf6;
			7'b010x100: rgb = 24'hf37d0d;
			7'b010x1x1: rgb = 24'hf37d6b;
			7'b010x110: rgb = 24'hfa80f9;
			7'b0001000: rgb = 24'h02f001;
			7'b00010x1: rgb = 24'h00f36b;
			7'b0001010: rgb = 24'h0ff3f2;
			7'b0x11000: rgb = 24'h71f504;
			7'b0x110x1: rgb = 24'h71f36b;
			7'b0x11010: rgb = 24'h71f3f4;
			7'b0101000: rgb = 24'hf3f30d;
			7'b01010x1: rgb = 24'hf3f36d;
			7'b0101010: rgb = 24'hfff3f9;
			7'b1000000: rgb = 24'h020702;
			7'b1000001: rgb = 24'h050663;
			7'b1000010: rgb = 24'h0507f1;
			7'b1x10000: rgb = 24'h670600;
			7'b1x100x1: rgb = 24'h680764;
			7'b1x10010: rgb = 24'h6807f1;
			7'b1100000: rgb = 24'hfd0704;
			7'b11000x1: rgb = 24'hff0764;
			7'b1100010: rgb = 24'hfd07f2;
			7'b100x100: rgb = 24'h046703;
			7'b100x1x1: rgb = 24'h046764;
			7'b100x110: rgb = 24'h0567f1;
			7'b1x1x100: rgb = 24'h686704;
			7'b1x1x1x1: rgb = 24'h686764;
			7'b1x1x110: rgb = 24'h6867f1;
			7'b110x100: rgb = 24'hfd6704;
			7'b110x1x1: rgb = 24'hfd6763;
			7'b110x110: rgb = 24'hfd67f1;
			7'b1001000: rgb = 24'h04f502;
			7'b10010x1: rgb = 24'h04f562;
			7'b1001010: rgb = 24'h04f5f1;
			7'b1x11000: rgb = 24'h68f500;
			7'b1x110x1: rgb = 24'h68f564;
			7'b1x11010: rgb = 24'h68f5f1;
			7'b1101000: rgb = 24'hfef504;
			7'b11010x1: rgb = 24'hfdf563;
			7'b1101010: rgb = 24'hfdf5f0;
			default: rgb = 0;
		endcase
	wire [15:0] px = ((rgb[23:16] * 16'd54) + (rgb[15:8] * 16'd183)) + (rgb[7:0] * 16'd18);
	always @(posedge clk_vid)
		if (ce_pix) begin
			{R_out, G_out, B_out} <= 0;
			case (mix)
				0, 1: {R_out, G_out, B_out} <= rgb;
				2: {G_out} <= {px[15:8]};
				3: {R_out, G_out} <= {px[15:8], px[15:8] - px[15:10]};
				4: {G_out, B_out} <= {px[15:8], px[15:8]};
				5: {R_out, G_out, B_out} <= {px[15:8], px[15:8], px[15:8]};
			endcase
			HSync_out <= HSync_in;
			VSync_out <= VSync_in;
			HBlank_out <= HBlank_in;
			VBlank_out <= VBlank_in;
		end
endmodule
