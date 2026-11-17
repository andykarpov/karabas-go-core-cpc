`default_nettype wire
module sna_hw_header (
	ga_inksel,
	ga_border,
	ga_inkr,
	ga_hromen,
	ga_lromen,
	ga_mode,
	ga_intcnt,
	ga_hcnt,
	ga_int_n,
	mmu_rammap,
	mmu_rom_select_shadow,
	crtc_addr,
	crtc_regs,
	crtc_hcc,
	crtc_row,
	crtc_line,
	crtc_c5,
	crtc_in_adj,
	crtc_hsc,
	crtc_hsync,
	crtc_vsync_r,
	crtc_vsw_elapsed,
	ppi_porta_in,
	ppi_portb_in,
	ppi_opc_r,
	ppi_mode,
	psg_addr,
	psg_regs,
	printer_data,
	model,
	crtc_type,
	fdc_motor,
	fdc_pcn_a,
	fdc_pcn_b,
	hdr
);
	input [4:0] ga_inksel;
	input [4:0] ga_border;
	input [79:0] ga_inkr;
	input ga_hromen;
	input ga_lromen;
	input [1:0] ga_mode;
	input [5:0] ga_intcnt;
	input [4:0] ga_hcnt;
	input ga_int_n;
	input [2:0] mmu_rammap;
	input [7:0] mmu_rom_select_shadow;
	input [4:0] crtc_addr;
	input [127:0] crtc_regs;
	input [7:0] crtc_hcc;
	input [6:0] crtc_row;
	input [4:0] crtc_line;
	input [4:0] crtc_c5;
	input crtc_in_adj;
	input [3:0] crtc_hsc;
	input crtc_hsync;
	input crtc_vsync_r;
	input [3:0] crtc_vsw_elapsed;
	input [7:0] ppi_porta_in;
	input [7:0] ppi_portb_in;
	input [7:0] ppi_opc_r;
	input [7:0] ppi_mode;
	input [7:0] psg_addr;
	input [127:0] psg_regs;
	input [7:0] printer_data;
	input [1:0] model;
	input crtc_type;
	input fdc_motor;
	input [7:0] fdc_pcn_a;
	input [7:0] fdc_pcn_b;
	output reg [1079:0] hdr;
	wire unused_bits = &{1'b0, ppi_mode[7], psg_addr[7:4], 1'b0};
	integer i;
	always @(*) begin
		hdr = {1080 {1'b0}};
		hdr[(8'h2e - 8'h2e) * 8+:8] = {3'b000, ga_inksel};
		for (i = 0; i < 16; i = i + 1)
			hdr[((32'h0000002f + i) - 32'h0000002e) * 8+:8] = {3'b000, ga_inkr[i * 5+:5]};
		hdr[(8'h3f - 8'h2e) * 8+:8] = {3'b000, ga_border};
		hdr[(8'h40 - 8'h2e) * 8+:8] = {4'b1000, ga_hromen, ga_lromen, ga_mode};
		hdr[(8'h41 - 8'h2e) * 8+:8] = (model == 2'd0 ? {5'b00000, mmu_rammap} : 8'h00);
		hdr[(8'h42 - 8'h2e) * 8+:8] = {3'b000, crtc_addr};
		for (i = 0; i < 16; i = i + 1)
			hdr[((32'h00000043 + i) - 32'h0000002e) * 8+:8] = crtc_regs[i * 8+:8];
		hdr[(8'h53 - 8'h2e) * 8+:8] = 8'h00;
		hdr[(8'h54 - 8'h2e) * 8+:8] = 8'h00;
		hdr[(8'h55 - 8'h2e) * 8+:8] = mmu_rom_select_shadow;
		hdr[(8'h56 - 8'h2e) * 8+:8] = ppi_porta_in;
		hdr[(8'h57 - 8'h2e) * 8+:8] = ppi_portb_in;
		hdr[(8'h58 - 8'h2e) * 8+:8] = ppi_opc_r;
		hdr[(8'h59 - 8'h2e) * 8+:8] = {1'b1, ppi_mode[6:0]};
		hdr[(8'h5a - 8'h2e) * 8+:8] = {4'h0, psg_addr[3:0]};
		for (i = 0; i < 16; i = i + 1)
			hdr[((32'h0000005b + i) - 32'h0000002e) * 8+:8] = psg_regs[i * 8+:8];
		hdr[(8'h6b - 8'h2e) * 8+:8] = (model == 2'd0 ? 8'd128 : 8'd64);
		hdr[(8'h6c - 8'h2e) * 8+:8] = 8'd0;
		hdr[(8'h6d - 8'h2e) * 8+:8] = (model == 2'd0 ? 8'd2 : (model == 2'd1 ? 8'd1 : 8'd0));
		hdr[(8'h9c - 8'h2e) * 8+:8] = {7'b0000000, fdc_motor};
		hdr[(8'h9d - 8'h2e) * 8+:8] = fdc_pcn_a;
		hdr[(8'h9e - 8'h2e) * 8+:8] = fdc_pcn_b;
		hdr[(8'h9f - 8'h2e) * 8+:8] = 8'h00;
		hdr[(8'ha0 - 8'h2e) * 8+:8] = 8'h00;
		hdr[(8'ha1 - 8'h2e) * 8+:8] = printer_data;
		hdr[(8'ha4 - 8'h2e) * 8+:8] = {7'b0000000, crtc_type};
		hdr[(8'ha9 - 8'h2e) * 8+:8] = crtc_hcc;
		hdr[(8'hab - 8'h2e) * 8+:8] = {1'b0, crtc_row};
		hdr[(8'hac - 8'h2e) * 8+:8] = {3'b000, crtc_line};
		hdr[(8'had - 8'h2e) * 8+:8] = (crtc_type ? {3'b000, crtc_c5} : (crtc_in_adj ? {3'b000, crtc_line} : 8'h00));
		hdr[(8'hae - 8'h2e) * 8+:8] = {4'h0, crtc_hsc};
		hdr[(8'haf - 8'h2e) * 8+:8] = {4'h0, crtc_vsw_elapsed};
		hdr[(8'hb0 - 8'h2e) * 8+:8] = {crtc_in_adj, 5'b00000, crtc_hsync, crtc_vsync_r};
		hdr[(8'hb1 - 8'h2e) * 8+:8] = 8'h00;
		hdr[(8'hb2 - 8'h2e) * 8+:8] = (ga_hcnt == 5'h00 ? 8'd2 : (ga_hcnt == 5'h01 ? 8'd1 : 8'd0));
		hdr[(8'hb3 - 8'h2e) * 8+:8] = {2'b00, ga_intcnt};
		hdr[(8'hb4 - 8'h2e) * 8+:8] = {7'b0000000, ~ga_int_n};
	end
endmodule
