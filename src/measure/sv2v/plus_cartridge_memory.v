module plus_cartridge_memory (
	clk,
	cold_reset,
	detach,
	load_begin,
	load_commit,
	load_abort,
	load_valid,
	load_page,
	load_offset,
	load_data,
	load_ready,
	load_error,
	cpu_valid,
	cpu_page,
	cpu_offset,
	cpu_ready,
	cpu_data,
	cpu_granted,
	image_valid,
	busy,
	mem_req,
	mem_write,
	mem_bank,
	mem_addr,
	mem_wdata,
	mem_ack,
	mem_grant,
	mem_rdata
);
	parameter [19:0] CLEAR_BYTES = 20'd524288;
	input clk;
	input cold_reset;
	input detach;
	input load_begin;
	input load_commit;
	input load_abort;
	input load_valid;
	input [5:0] load_page;
	input [14:0] load_offset;
	input [7:0] load_data;
	output reg load_ready;
	output reg load_error;
	input cpu_valid;
	input [4:0] cpu_page;
	input [13:0] cpu_offset;
	output reg cpu_ready;
	output reg [7:0] cpu_data;
	output reg cpu_granted;
	output reg image_valid;
	output wire busy;
	output reg mem_req;
	output reg mem_write;
	output reg [1:0] mem_bank;
	output reg [22:0] mem_addr;
	output reg [7:0] mem_wdata;
	input mem_ack;
	input mem_grant;
	input [7:0] mem_rdata;
	localparam [22:0] CARTRIDGE_BASE = 23'h080000;
	localparam [19:0] CLEAR_LAST_EXT = CLEAR_BYTES - 20'd1;
	localparam [1:0] REQUEST_CLEAR = 2'd0;
	localparam [1:0] REQUEST_LOAD = 2'd1;
	localparam [1:0] REQUEST_CPU = 2'd2;
	reg load_active;
	reg clear_active;
	reg [18:0] clear_index;
	reg commit_pending;
	reg [1:0] request_kind;
	reg discard_request;
	reg load_consumed;
	reg cpu_consumed;
	reg begin_consumed;
	reg commit_consumed;
	reg abort_consumed;
	reg detach_consumed;
	wire detach_event = detach && !detach_consumed;
	wire abort_event = (load_abort && !abort_consumed) && !detach;
	wire begin_event = (((load_begin && !begin_consumed) && !cold_reset) && !load_abort) && !detach;
	wire commit_event = ((((load_commit && !commit_consumed) && !load_begin) && !cold_reset) && !load_abort) && !detach;
	assign busy = load_active;
	initial begin
		load_ready = 1'b0;
		load_error = 1'b0;
		cpu_ready = 1'b0;
		cpu_granted = 1'b0;
		cpu_data = 8'hff;
		image_valid = 1'b0;
		mem_req = 1'b0;
		mem_write = 1'b0;
		mem_bank = 2'b11;
		mem_addr = CARTRIDGE_BASE;
		mem_wdata = 8'h00;
		load_active = 1'b0;
		clear_active = 1'b0;
		clear_index = 19'd0;
		commit_pending = 1'b0;
		request_kind = REQUEST_CLEAR;
		discard_request = 1'b0;
		load_consumed = 1'b0;
		cpu_consumed = 1'b0;
		begin_consumed = 1'b0;
		commit_consumed = 1'b0;
		abort_consumed = 1'b0;
		detach_consumed = 1'b0;
	end
	initial if ((CLEAR_BYTES < 20'd1) || (CLEAR_BYTES > 20'd524288)) begin
		$display("ERROR: CLEAR_BYTES must be in the range 1..524288");
		$finish;
	end
	always @(posedge clk) begin
		load_ready <= 1'b0;
		cpu_ready <= 1'b0;
		if (!load_valid)
			load_consumed <= 1'b0;
		if (!cpu_valid)
			cpu_consumed <= 1'b0;
		begin_consumed <= load_begin;
		commit_consumed <= load_commit;
		abort_consumed <= load_abort;
		detach_consumed <= detach;
		if (detach_event) begin
			image_valid <= 1'b0;
			load_active <= 1'b0;
			clear_active <= 1'b0;
			clear_index <= 19'd0;
			commit_pending <= 1'b0;
			load_error <= 1'b0;
			load_consumed <= load_valid;
			cpu_consumed <= cpu_valid;
			if (mem_req && !mem_ack)
				discard_request <= 1'b1;
			else begin
				mem_req <= 1'b0;
				discard_request <= 1'b0;
			end
		end
		else if (abort_event) begin
			image_valid <= 1'b0;
			load_active <= 1'b0;
			clear_active <= 1'b0;
			clear_index <= 19'd0;
			commit_pending <= 1'b0;
			load_error <= 1'b0;
			load_consumed <= load_valid;
			cpu_consumed <= cpu_valid;
			if (mem_req && !mem_ack)
				discard_request <= 1'b1;
			else begin
				mem_req <= 1'b0;
				discard_request <= 1'b0;
			end
		end
		else if (cold_reset) begin
			load_active <= 1'b0;
			clear_active <= 1'b0;
			clear_index <= 19'd0;
			commit_pending <= 1'b0;
			load_error <= 1'b0;
			load_consumed <= load_valid;
			cpu_consumed <= cpu_valid;
			if (mem_req && !mem_ack)
				discard_request <= 1'b1;
			else begin
				mem_req <= 1'b0;
				discard_request <= 1'b0;
			end
		end
		else if (begin_event) begin
			image_valid <= 1'b0;
			load_active <= 1'b1;
			clear_active <= 1'b1;
			clear_index <= 19'd0;
			commit_pending <= 1'b0;
			load_error <= 1'b0;
			load_consumed <= load_valid;
			cpu_consumed <= 1'b0;
			if (mem_req && !mem_ack)
				discard_request <= 1'b1;
			else begin
				mem_req <= 1'b0;
				discard_request <= 1'b0;
			end
		end
		else begin
			if (commit_event) begin
				if (load_active)
					commit_pending <= 1'b1;
			end
			if (mem_req) begin
				if (mem_ack) begin
					mem_req <= 1'b0;
					if (discard_request || ((request_kind == REQUEST_CPU) && !cpu_valid))
						discard_request <= 1'b0;
					else
						case (request_kind)
							REQUEST_CLEAR:
								if (clear_index == CLEAR_LAST_EXT[18:0])
									clear_active <= 1'b0;
								else begin
									clear_index <= clear_index + 19'd1;
									mem_req <= 1'b1;
									mem_write <= 1'b1;
									mem_bank <= 2'b11;
									mem_addr <= (CARTRIDGE_BASE + {4'b0000, clear_index}) + 23'd1;
									mem_wdata <= 8'h00;
								end
							REQUEST_LOAD: load_ready <= 1'b1;
							REQUEST_CPU: begin
								cpu_ready <= 1'b1;
								cpu_data <= mem_rdata;
							end
							default:
								;
						endcase
				end
				else if ((request_kind == REQUEST_CPU) && !cpu_valid)
					discard_request <= 1'b1;
			end
			else if (load_active) begin
				if (clear_active) begin
					request_kind <= REQUEST_CLEAR;
					mem_req <= 1'b1;
					mem_write <= 1'b1;
					mem_bank <= 2'b11;
					mem_addr <= CARTRIDGE_BASE + {4'b0000, clear_index};
					mem_wdata <= 8'h00;
				end
				else if (load_valid && !load_consumed) begin
					load_consumed <= 1'b1;
					if (load_page[5] || load_offset[14]) begin
						load_ready <= 1'b1;
						load_error <= 1'b1;
					end
					else begin
						request_kind <= REQUEST_LOAD;
						mem_req <= 1'b1;
						mem_write <= 1'b1;
						mem_bank <= 2'b11;
						mem_addr <= {4'b0001, load_page[4:0], load_offset[13:0]};
						mem_wdata <= load_data;
					end
				end
				else if (commit_pending && !load_error) begin
					image_valid <= 1'b1;
					load_active <= 1'b0;
					commit_pending <= 1'b0;
				end
			end
			else if (cpu_valid && !cpu_consumed) begin
				cpu_consumed <= 1'b1;
				if (image_valid) begin
					request_kind <= REQUEST_CPU;
					mem_req <= 1'b1;
					mem_write <= 1'b0;
					mem_bank <= 2'b11;
					mem_addr <= {4'b0001, cpu_page, cpu_offset};
					mem_wdata <= 8'h00;
				end
				else begin
					cpu_ready <= 1'b1;
					cpu_data <= 8'hff;
				end
			end
		end
	end
	always @(posedge clk)
		if ((((((((detach_event || abort_event) || cold_reset) || begin_event) || !mem_req) || mem_ack) || (request_kind != REQUEST_CPU)) || discard_request) || !cpu_valid)
			cpu_granted <= 1'b0;
		else if (mem_grant)
			cpu_granted <= 1'b1;
endmodule
