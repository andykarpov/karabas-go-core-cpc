module ltc2308_tape (
	reset,
	clk,
	ADC_BUS,
	dout,
	active,
	adc_sync,
	adc_data
);
	parameter HIST_LOW = 16;
	parameter HIST_HIGH = 64;
	parameter ADC_RATE = 48000;
	parameter CLK_RATE = 50000000;
	parameter NUM_CH = 1;
	input reset;
	input clk;
	inout [3:0] ADC_BUS;
	output reg dout;
	output wire active;
	output wire adc_sync;
	output wire [(NUM_CH * 12) - 1:0] adc_data;
	always @(posedge clk) dout <= ADC_BUS[0];
	assign active = ADC_BUS[1];
	assign adc_sync = ADC_BUS[2];
	assign adc_data = {NUM_CH * 12 {ADC_BUS[3]}};
endmodule
