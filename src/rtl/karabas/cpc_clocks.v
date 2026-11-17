`timescale 1ns / 1ps
`default_nettype wire
/*
 cpc_clocks.v

 The clocks of the CPC core from CLK_50MHZ (the pin): DCM_CLKGEN 50 * 32 / 25 = 64 MHz exactly
 (a PLL alone cannot: VCO 400..1000 MHz, PFD >= 19 MHz, no multiple of 64 and 160 from 50 or 25)
 -> BUFG -> PLL (x10, VCO 640 MHz, cleans the jitter of CLKFX for HDMI):
   clk_sys     /10  64 MHz: the machine (upstream clk_sys: ce_16 = 16 MHz, ce_u765 8 MHz), the SRAM,
                    the MCU link, the line doubler, the DAC
   clk_pix     /20  32 MHz: the doubled picture (1024 x 625 at 50 Hz), the OSD, HDMI (phase aligned
                    to clk_sys: the paths between them are timed)
   clk_hdmi    /4   160 MHz and clk_hdmi_n (180 degrees): the TMDS serialiser
   clk_8       /80  8 MHz: FT_CLK_OUT
 The PLL is held in reset until the DCM locks.
*/
module cpc_clocks (
	input wire clk_in,
	output wire clk_sys,
	output wire clk_pix,
	output wire clk_hdmi,
	output wire clk_hdmi_n,
	output wire clk_8,
	output wire locked
);

wire clk_50_ibufg, clk_50_bufg;
IBUFG ibufg_50 (.I(clk_in), .O(clk_50_ibufg));
BUFG bufg_50 (.I(clk_50_ibufg), .O(clk_50_bufg));

wire fx, fx_buf, dcm_locked;
DCM_CLKGEN #(
	.CLKFX_MULTIPLY(32),
	.CLKFX_DIVIDE(25),
	.CLKFXDV_DIVIDE(2),
	.CLKFX_MD_MAX(1.28),
	.CLKIN_PERIOD(20.0),
	.SPREAD_SPECTRUM("NONE"),
	.STARTUP_WAIT("FALSE")
) dcm (
	.CLKIN(clk_50_bufg),
	.RST(1'b0),
	.FREEZEDCM(1'b0),
	.PROGCLK(1'b0),
	.PROGDATA(1'b0),
	.PROGEN(1'b0),
	.CLKFX(fx),
	.CLKFX180(),
	.CLKFXDV(),
	.LOCKED(dcm_locked),
	.PROGDONE(),
	.STATUS()
);
BUFG bufg_fx (.I(fx), .O(fx_buf));

wire [5:0] pll_clk;
kg_pll #(
	.CLKIN_PERIOD(15.625),
	.DIVCLK_DIVIDE(1),
	.CLKFBOUT_MULT(10),
	.CLKOUT0_DIVIDE(10),
	.CLKOUT1_DIVIDE(20),
	.CLKOUT2_DIVIDE(4),
	.CLKOUT3_DIVIDE(4),
	.CLKOUT3_PHASE(180.0),
	.CLKOUT4_DIVIDE(80),
	.IBUFG(0),
	.BUFG_MASK(6'b011111)
) pll (
	.clk_in(fx_buf),
	.rst(!dcm_locked),
	.clk_out(pll_clk),
	.locked(locked)
);

assign clk_sys = pll_clk[0];
assign clk_pix = pll_clk[1];
assign clk_hdmi = pll_clk[2];
assign clk_hdmi_n = pll_clk[3];
assign clk_8 = pll_clk[4];

endmodule
