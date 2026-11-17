`default_nettype wire
module Amstrad_MMU (
	CLK,
	reset,
	ram64k,
	romen_n,
	rom_map,
	io_WR,
	D,
	A,
	sna_load,
	sna_ram_config,
	sna_rom_select,
	ram_A,
	snap_rammap,
	snap_rampage,
	snap_rom_select_shadow
);
	input CLK;
	input reset;
	input ram64k;
	input romen_n;
	input [255:0] rom_map;
	input io_WR;
	input [7:0] D;
	input [15:0] A;
	input sna_load;
	input [7:0] sna_ram_config;
	input [7:0] sna_rom_select;
	output reg [22:0] ram_A;
	output wire [2:0] snap_rammap;
	output wire [4:0] snap_rampage;
	output wire [7:0] snap_rom_select_shadow;
	reg [2:0] RAMmap;
	reg [4:0] RAMpage;
	reg [7:0] ROMbank;
	reg [7:0] rom_select_shadow;
	always @(posedge CLK) begin : sv2v_autoblock_1
		reg old_wr;
		if (reset) begin
			ROMbank <= 0;
			rom_select_shadow <= 8'd0;
			RAMmap <= 0;
			RAMpage <= 3;
			old_wr <= 1'b0;
		end
		else if (sna_load) begin
			RAMmap <= sna_ram_config[2:0];
			RAMpage <= {2'b00, sna_ram_config[5:3]} + 5'd3;
			ROMbank <= (rom_map[sna_rom_select] ? sna_rom_select : 8'h00);
			rom_select_shadow <= sna_rom_select;
		end
		else begin
			old_wr <= io_WR;
			if (~old_wr & io_WR) begin
				if ((~A[15] && (D[7:6] == 'b11)) && ~ram64k) begin
					RAMpage <= {1'b0, ~A[8], D[5:3]} + 5'd3;
					RAMmap <= D[2:0];
				end
				if (~A[13]) begin
					ROMbank <= (rom_map[D] ? D : 8'h00);
					rom_select_shadow <= D;
				end
			end
		end
	end
	assign snap_rammap = RAMmap;
	assign snap_rampage = RAMpage;
	assign snap_rom_select_shadow = rom_select_shadow;
	always @(*) begin
		casex ({romen_n, RAMmap, A[15:14]})
			'b0xxxxx: ram_A[22:14] = {9 {A[15]}} & {1'b1, ROMbank};
			'b10x111, 'b1010xx: ram_A[22:14] = {2'b00, RAMpage, A[15:14]};
			'b101101: ram_A[22:14] = 9'h00b;
			'b11xx01: ram_A[22:14] = {2'b00, RAMpage, RAMmap[1:0]};
			default: ram_A[22:14] = {7'h02, A[15:14]};
		endcase
		ram_A[13:0] = A[13:0];
	end
endmodule
