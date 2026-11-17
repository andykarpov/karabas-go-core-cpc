`default_nettype wire
module plus_sna_header (
	clk,
	sna_download,
	wr,
	addr,
	data,
	version,
	v3,
	ga_inksel,
	ga_palette,
	ga_config,
	crtc_addr,
	crtc_regs,
	rom_select,
	crtc_hcc,
	crtc_line,
	crtc_raster,
	crtc_vta,
	crtc_hsw,
	crtc_vsw,
	crtc_vs,
	crtc_hs,
	crtc_adj,
	ga_vsdelay,
	ga_intcnt,
	int_pending
);
	input clk;
	input sna_download;
	input wr;
	input [7:0] addr;
	input [7:0] data;
	output wire [7:0] version;
	output wire v3;
	output wire [4:0] ga_inksel;
	output wire [135:0] ga_palette;
	output wire [7:0] ga_config;
	output wire [4:0] crtc_addr;
	output wire [143:0] crtc_regs;
	output wire [7:0] rom_select;
	output wire [7:0] crtc_hcc;
	output wire [6:0] crtc_line;
	output wire [4:0] crtc_raster;
	output wire [4:0] crtc_vta;
	output wire [3:0] crtc_hsw;
	output wire [3:0] crtc_vsw;
	output wire crtc_vs;
	output wire crtc_hs;
	output wire crtc_adj;
	output wire [1:0] ga_vsdelay;
	output wire [5:0] ga_intcnt;
	output wire int_pending;
	reg [7:0] version_r;
	reg [4:0] ga_inksel_r;
	reg [135:0] ga_palette_r;
	reg [7:0] ga_config_r;
	reg [4:0] crtc_addr_r;
	reg [143:0] crtc_regs_r;
	reg [7:0] rom_select_r;
	reg [7:0] crtc_hcc_r;
	reg [6:0] crtc_line_r;
	reg [4:0] crtc_raster_r;
	reg [4:0] crtc_vta_r;
	reg [3:0] crtc_hsw_r;
	reg [3:0] crtc_vsw_r;
	reg b0_vs_r;
	reg b0_hs_r;
	reg b0_adj_r;
	reg [1:0] ga_vsdelay_r;
	reg [5:0] ga_intcnt_r;
	reg int_req_r;
	reg sna_download_d;
	assign version = version_r;
	assign v3 = version_r == 8'd3;
	assign ga_inksel = ga_inksel_r;
	assign ga_palette = ga_palette_r;
	assign ga_config = ga_config_r;
	assign crtc_addr = crtc_addr_r;
	assign crtc_regs = crtc_regs_r;
	assign rom_select = rom_select_r;
	assign crtc_hcc = (v3 ? crtc_hcc_r : 8'd0);
	assign crtc_line = (v3 ? crtc_line_r : 7'd0);
	assign crtc_raster = (v3 ? crtc_raster_r : 5'd0);
	assign crtc_vta = (v3 ? crtc_vta_r : 5'd0);
	assign crtc_hsw = (v3 ? crtc_hsw_r : 4'd0);
	assign crtc_vsw = (v3 ? crtc_vsw_r : 4'd0);
	assign crtc_vs = (v3 ? b0_vs_r : 1'b0);
	assign crtc_hs = (v3 ? b0_hs_r : 1'b0);
	assign crtc_adj = (v3 ? b0_adj_r : 1'b0);
	assign ga_vsdelay = (v3 ? ga_vsdelay_r : 2'd0);
	assign ga_intcnt = (v3 ? ga_intcnt_r : 6'd0);
	assign int_pending = (v3 ? int_req_r : 1'b0);
	always @(posedge clk) begin
		sna_download_d <= sna_download;
		if (sna_download && !sna_download_d) begin
			version_r <= 8'd0;
			ga_inksel_r <= 5'd0;
			ga_palette_r <= 136'd0;
			ga_config_r <= 8'd0;
			crtc_addr_r <= 5'd0;
			crtc_regs_r <= 144'd0;
			rom_select_r <= 8'd0;
			crtc_hcc_r <= 8'd0;
			crtc_line_r <= 7'd0;
			crtc_raster_r <= 5'd0;
			crtc_vta_r <= 5'd0;
			crtc_hsw_r <= 4'd0;
			crtc_vsw_r <= 4'd0;
			b0_vs_r <= 1'b0;
			b0_hs_r <= 1'b0;
			b0_adj_r <= 1'b0;
			ga_vsdelay_r <= 2'd0;
			ga_intcnt_r <= 6'd0;
			int_req_r <= 1'b0;
		end
		else if (wr) begin
			case (addr)
				8'h10: version_r <= data;
				8'h2e: ga_inksel_r <= data[4:0];
				8'h40: ga_config_r <= data;
				8'h42: crtc_addr_r <= data[4:0];
				8'h55: rom_select_r <= data;
				8'ha9: crtc_hcc_r <= data;
				8'hab: crtc_line_r <= data[6:0];
				8'hac: crtc_raster_r <= data[4:0];
				8'had: crtc_vta_r <= data[4:0];
				8'hae: crtc_hsw_r <= data[3:0];
				8'haf: crtc_vsw_r <= data[3:0];
				8'hb0: {b0_adj_r, b0_hs_r, b0_vs_r} <= {data[7], data[1], data[0]};
				8'hb2: ga_vsdelay_r <= data[1:0];
				8'hb3: ga_intcnt_r <= data[5:0];
				8'hb4: int_req_r <= data[0];
				default:
					;
			endcase
			if ((addr >= 8'h2f) && (addr <= 8'h3f))
				ga_palette_r[(addr - 8'h2f) * 8+:8] <= data;
			if ((addr >= 8'h43) && (addr <= 8'h54))
				crtc_regs_r[(addr - 8'h43) * 8+:8] <= data;
		end
	end
	initial begin
		version_r = 8'd0;
		ga_inksel_r = 5'd0;
		ga_palette_r = 136'd0;
		ga_config_r = 8'd0;
		crtc_addr_r = 5'd0;
		crtc_regs_r = 144'd0;
		rom_select_r = 8'd0;
		crtc_hcc_r = 8'd0;
		crtc_line_r = 7'd0;
		crtc_raster_r = 5'd0;
		crtc_vta_r = 5'd0;
		crtc_hsw_r = 4'd0;
		crtc_vsw_r = 4'd0;
		b0_vs_r = 1'b0;
		b0_hs_r = 1'b0;
		b0_adj_r = 1'b0;
		ga_vsdelay_r = 2'd0;
		ga_intcnt_r = 6'd0;
		int_req_r = 1'b0;
		sna_download_d = 1'b0;
	end
endmodule
