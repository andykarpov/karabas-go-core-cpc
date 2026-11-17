module i8255 (
	reset,
	clk_sys,
	addr,
	idata,
	odata,
	cs,
	we,
	oe,
	ipa,
	opa,
	ipb,
	opb,
	ipc,
	opc,
	plus_mode,
	sna_load,
	sna_opa,
	sna_opb,
	sna_opc,
	sna_control,
	snap_opc_r,
	snap_mode
);
	input reset;
	input clk_sys;
	input [1:0] addr;
	input [7:0] idata;
	output reg [7:0] odata;
	input cs;
	input we;
	input oe;
	input [7:0] ipa;
	output wire [7:0] opa;
	input [7:0] ipb;
	output wire [7:0] opb;
	input [7:0] ipc;
	output wire [7:0] opc;
	input plus_mode;
	input sna_load;
	input [7:0] sna_opa;
	input [7:0] sna_opb;
	input [7:0] sna_opc;
	input [7:0] sna_control;
	output wire [7:0] snap_opc_r;
	output wire [7:0] snap_mode;
	reg [7:0] mode;
	reg [7:0] opa_r;
	reg [7:0] opb_r;
	reg [7:0] opc_r;
	assign opa = (~mode[4] | mode[6] ? opa_r : 8'hff);
	assign opc[7:4] = (plus_mode | ~mode[3] ? opc_r[7:4] : 4'hf);
	assign opb = (~mode[1] ? opb_r : 8'hff);
	assign opc[3:0] = (plus_mode | ~mode[0] ? opc_r[3:0] : 4'hf);
	reg [7:0] maskC;
	always @(*)
		casex ({mode[6:4], mode[2]})
			'b1xx0: maskC = 8'b00000111;
			'b1xx1: maskC = 8'b00000000;
			'b110: maskC = 8'b00110111;
			'b111: maskC = 8'b00110000;
			'b100: maskC = 8'b11000111;
			'b101: maskC = 8'b11000000;
			'b00x1: maskC = 8'b11111000;
			default: maskC = 8'b11111111;
		endcase
	wire [3:0] tapemotor = (((~mode[6] & mode[5]) & ~mode[4]) & ~mode[2] ? 4'h2 : 4'h0);
	always @(*)
		casex ({oe & cs, addr})
			'b0xx: odata = 8'hff;
			'b100: odata = (mode[4] | mode[6] ? ipa : opa_r);
			'b101: odata = (plus_mode | mode[1] ? ipb : opb_r);
			'b110: odata = (plus_mode ? opc_r : {(mode[3] ? (ipc[7:4] & maskC[7:4]) | tapemotor : opc_r[7:4]), (mode[0] ? ipc[3:0] & maskC[3:0] : opc_r[3:0])});
			'b111: odata = (plus_mode ? {8 {mode[4]}} : mode);
		endcase
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_we;
		old_we <= we;
		if (reset)
			{opa_r, opb_r, opc_r, mode} <= 32'h0000009b;
		else if (sna_load)
			{opa_r, opb_r, opc_r, mode} <= {sna_opa, sna_opb, sna_opc, sna_control};
		else if ((~old_we & we) & cs)
			case (addr)
				0: opa_r <= idata;
				1:
					if (!plus_mode)
						opb_r <= idata;
				2: opc_r <= (plus_mode ? idata : (idata & maskC) | (opc_r & ~maskC));
				default:
					if (~idata[7])
						opc_r[idata[3:1]] <= idata[0];
					else if (plus_mode)
						mode <= idata;
					else
						{opa_r, opb_r, opc_r, mode} <= {24'h000000, idata};
			endcase
	end
	assign snap_opc_r = opc_r;
	assign snap_mode = mode;
endmodule
