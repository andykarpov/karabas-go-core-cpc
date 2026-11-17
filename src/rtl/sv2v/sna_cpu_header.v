`default_nettype wire
module sna_cpu_header (
	clk,
	sna_download,
	wr,
	addr,
	data,
	menu_model,
	cpu_dir,
	ram_config,
	ppi_a,
	ppi_b,
	ppi_c,
	ppi_control,
	psg_addr,
	psg_regs,
	mem_size,
	model
);
	input clk;
	input sna_download;
	input wr;
	input [7:0] addr;
	input [7:0] data;
	input [1:0] menu_model;
	output wire [211:0] cpu_dir;
	output wire [7:0] ram_config;
	output wire [7:0] ppi_a;
	output wire [7:0] ppi_b;
	output wire [7:0] ppi_c;
	output wire [7:0] ppi_control;
	output wire [3:0] psg_addr;
	output wire [127:0] psg_regs;
	output wire [15:0] mem_size;
	output wire [1:0] model;
	reg [211:0] cpu_dir_r;
	reg [7:0] ram_config_r;
	reg [7:0] ppi_a_r;
	reg [7:0] ppi_b_r;
	reg [7:0] ppi_c_r;
	reg [7:0] ppi_control_r;
	reg [3:0] psg_addr_r;
	reg [127:0] psg_regs_r;
	reg [15:0] mem_size_r;
	reg [1:0] model_r;
	reg sna_download_d;
	assign cpu_dir = cpu_dir_r;
	assign ram_config = ram_config_r;
	assign ppi_a = ppi_a_r;
	assign ppi_b = ppi_b_r;
	assign ppi_c = ppi_c_r;
	assign ppi_control = ppi_control_r;
	assign psg_addr = psg_addr_r;
	assign psg_regs = psg_regs_r;
	assign mem_size = mem_size_r;
	assign model = model_r;
	always @(posedge clk) begin
		sna_download_d <= sna_download;
		if (sna_download && !sna_download_d) begin
			cpu_dir_r <= 212'd0;
			psg_regs_r <= 128'd0;
			mem_size_r <= 16'd64;
			model_r <= menu_model;
			ppi_control_r <= 8'h9b;
		end
		else if (wr) begin
			case (addr)
				8'h11: cpu_dir_r[15:8] <= data;
				8'h12: cpu_dir_r[7:0] <= data;
				8'h13: cpu_dir_r[87:80] <= data;
				8'h14: cpu_dir_r[95:88] <= data;
				8'h15: cpu_dir_r[103:96] <= data;
				8'h16: cpu_dir_r[111:104] <= data;
				8'h17: cpu_dir_r[119:112] <= data;
				8'h18: cpu_dir_r[127:120] <= data;
				8'h19: cpu_dir_r[47:40] <= data;
				8'h1a: cpu_dir_r[39:32] <= data;
				8'h1b: cpu_dir_r[210] <= data[0];
				8'h1c: cpu_dir_r[211] <= data[0];
				8'h1d: cpu_dir_r[135:128] <= data;
				8'h1e: cpu_dir_r[143:136] <= data;
				8'h1f: cpu_dir_r[199:192] <= data;
				8'h20: cpu_dir_r[207:200] <= data;
				8'h21: cpu_dir_r[55:48] <= data;
				8'h22: cpu_dir_r[63:56] <= data;
				8'h23: cpu_dir_r[71:64] <= data;
				8'h24: cpu_dir_r[79:72] <= data;
				8'h25: cpu_dir_r[209:208] <= data[1:0];
				8'h26: cpu_dir_r[31:24] <= data;
				8'h27: cpu_dir_r[23:16] <= data;
				8'h28: cpu_dir_r[151:144] <= data;
				8'h29: cpu_dir_r[159:152] <= data;
				8'h2a: cpu_dir_r[167:160] <= data;
				8'h2b: cpu_dir_r[175:168] <= data;
				8'h2c: cpu_dir_r[183:176] <= data;
				8'h2d: cpu_dir_r[191:184] <= data;
				8'h41: ram_config_r <= data;
				8'h56: ppi_a_r <= data;
				8'h57: ppi_b_r <= data;
				8'h58: ppi_c_r <= data;
				8'h59: ppi_control_r <= data;
				8'h5a: psg_addr_r <= data[3:0];
				8'h6b: mem_size_r[7:0] <= data;
				8'h6c: begin
					mem_size_r[15:8] <= data;
					if ({data, mem_size_r[7:0]} > 16'd64)
						model_r <= 2'd0;
					else if (cpu_dir_r[79:64] == 16'h0038)
						model_r <= 2'd2;
				end
				8'h6d:
					if (mem_size_r > 16'd64)
						model_r <= 2'd0;
					else
						case (data)
							8'd0: model_r <= 2'd2;
							8'd1: model_r <= 2'd1;
							8'd2, 8'd4, 8'd5, 8'd6: model_r <= 2'd0;
							default:
								;
						endcase
				default:
					;
			endcase
			if ((addr >= 8'h5b) && (addr <= 8'h6a))
				psg_regs_r[(addr - 8'h5b) * 8+:8] <= data;
		end
	end
	initial begin
		cpu_dir_r = 212'd0;
		ram_config_r = 8'd0;
		ppi_a_r = 8'd0;
		ppi_b_r = 8'd0;
		ppi_c_r = 8'd0;
		ppi_control_r = 8'h9b;
		psg_addr_r = 4'd0;
		psg_regs_r = 128'd0;
		mem_size_r = 16'd64;
		model_r = 2'd0;
		sna_download_d = 1'b0;
	end
endmodule
