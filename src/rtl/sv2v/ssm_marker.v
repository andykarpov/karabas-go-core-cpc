`default_nettype wire
module ssm_marker (
	clk,
	reset,
	enable,
	m1_fetch,
	bus_data,
	sync_observation,
	ce_pix,
	hsync,
	vsync,
	field,
	last_code,
	event_count,
	dropped_count,
	event_stb,
	ddram_addr,
	ddram_din,
	ddram_be,
	ddram_burstcnt,
	ddram_we,
	ddram_busy
);
	parameter [31:0] DDR_BASE = 32'h30000000;
	parameter SLOT_BITS = 6;
	parameter [31:0] MAGIC = 32'h53534d31;
	input clk;
	input reset;
	input enable;
	input m1_fetch;
	input [7:0] bus_data;
	input [20:0] sync_observation;
	input ce_pix;
	input hsync;
	input vsync;
	input field;
	output reg [15:0] last_code;
	output reg [31:0] event_count;
	output reg [7:0] dropped_count;
	output wire event_stb;
	output reg [28:0] ddram_addr;
	output reg [63:0] ddram_din;
	output wire [7:0] ddram_be;
	output wire [7:0] ddram_burstcnt;
	output reg ddram_we;
	input ddram_busy;
	localparam [28:0] BASE_WORD = DDR_BASE[31:3];
	assign ddram_be = 8'hff;
	assign ddram_burstcnt = 8'd1;
	wire active = enable & ~reset;
	reg [23:0] frame = 24'd0;
	reg [9:0] line = 10'd0;
	reg [7:0] hpos = 8'd0;
	reg [31:0] tick = 32'd0;
	reg hsync_d = 1'b0;
	reg vsync_d = 1'b0;
	always @(posedge clk) begin
		tick <= tick + 1'd1;
		if (!active) begin
			frame <= 24'd0;
			line <= 10'd0;
			hpos <= 8'd0;
			tick <= 32'd0;
			hsync_d <= hsync;
			vsync_d <= vsync;
		end
		else if (ce_pix) begin
			hsync_d <= hsync;
			vsync_d <= vsync;
			hpos <= hpos + 1'd1;
			if (hsync & ~hsync_d) begin
				hpos <= 8'd0;
				line <= line + 1'd1;
			end
			if (vsync & ~vsync_d) begin
				line <= 10'd0;
				frame <= frame + 1'd1;
			end
		end
	end
	reg m1_fetch_d = 1'b0;
	reg [7:0] fetch_data = 8'd0;
	reg fetch_stb = 1'b0;
	wire fetch_end = m1_fetch_d & ~m1_fetch;
	reg [31:0] tick_at_fetch = 32'd0;
	reg [20:0] observation_at_fetch = 21'd0;
	reg [42:0] pos_at_fetch = 43'd0;
	always @(posedge clk) begin
		m1_fetch_d <= m1_fetch;
		fetch_stb <= fetch_end;
		if (m1_fetch)
			fetch_data <= bus_data;
		if (!active) begin
			m1_fetch_d <= 1'b0;
			fetch_stb <= 1'b0;
		end
	end
	always @(posedge clk)
		if (!active) begin
			tick_at_fetch <= 32'd0;
			observation_at_fetch <= 21'd0;
			pos_at_fetch <= 43'd0;
		end
		else if (fetch_end) begin
			tick_at_fetch <= tick;
			observation_at_fetch <= sync_observation;
			pos_at_fetch <= {field, hpos, line, frame};
		end
	function ssm_byte_allowed;
		input [7:0] b;
		ssm_byte_allowed = ((((((b <= 8'h3f) || ((b >= 8'h7f) && (b <= 8'h9f))) || ((b >= 8'ha4) && (b <= 8'ha7))) || ((b >= 8'hac) && (b <= 8'haf))) || ((b >= 8'hb4) && (b <= 8'hb7))) || ((b >= 8'hbc) && (b <= 8'hbf))) || (b >= 8'hc0);
	endfunction
	localparam [1:0] S_ED1 = 2'd0;
	localparam [1:0] S_LL = 2'd1;
	localparam [1:0] S_ED2 = 2'd2;
	localparam [1:0] S_HH = 2'd3;
	reg [1:0] state = S_ED1;
	reg [7:0] ll = 8'd0;
	reg hit = 1'b0;
	reg [15:0] hit_code = 16'd0;
	reg [31:0] hit_tick = 32'd0;
	reg [42:0] hit_pos = 43'd0;
	reg [20:0] hit_observation = 21'd0;
	assign event_stb = hit;
	always @(posedge clk) begin
		hit <= 1'b0;
		if (!active) begin
			state <= S_ED1;
			ll <= 8'd0;
		end
		else if (fetch_stb)
			case (state)
				S_ED1: state <= (fetch_data == 8'hed ? S_LL : S_ED1);
				S_LL:
					if (ssm_byte_allowed(fetch_data)) begin
						ll <= fetch_data;
						state <= S_ED2;
					end
					else
						state <= S_ED1;
				S_ED2: state <= (fetch_data == 8'hed ? S_HH : S_ED1);
				S_HH: begin
					if (ssm_byte_allowed(fetch_data)) begin
						hit <= 1'b1;
						hit_code <= {fetch_data, ll};
						hit_tick <= tick_at_fetch;
						hit_observation <= observation_at_fetch;
						hit_pos <= pos_at_fetch;
					end
					state <= S_ED1;
				end
			endcase
	end
	localparam [2:0] W_MAGIC = 3'd0;
	localparam [2:0] W_INIT_HDR = 3'd1;
	localparam [2:0] W_IDLE = 3'd2;
	localparam [2:0] W_RECA = 3'd3;
	localparam [2:0] W_RECB = 3'd4;
	localparam [2:0] W_HDR = 3'd5;
	localparam [2:0] W_REPUB = 3'd6;
	localparam [7:0] RING_ENTRIES = 8'd1 << SLOT_BITS;
	reg [2:0] wstate = W_MAGIC;
	reg [31:0] written = 32'd0;
	reg [7:0] pub_dropped = 8'd0;
	reg [63:0] rec_a = 64'd0;
	reg [63:0] rec_b = 64'd0;
	reg pend = 1'b0;
	reg quiesce_pending = 1'b0;
	wire [SLOT_BITS - 1:0] slot = written[SLOT_BITS - 1:0];
	wire [28:0] slot_off = {{28 - SLOT_BITS {1'b0}}, slot, 1'b0};
	wire [63:0] capture_a = {hit_observation[20:16], hit_pos, hit_code};
	wire [63:0] capture_b = {hit_observation[15:0], hit_tick, event_count[15:0]};
	always @(posedge clk)
		if (!active) begin
			if (ddram_we & ddram_busy)
				quiesce_pending <= 1'b1;
			else begin
				quiesce_pending <= 1'b0;
				ddram_we <= 1'b0;
				wstate <= W_MAGIC;
				written <= 32'd0;
				event_count <= 32'd0;
				dropped_count <= 8'd0;
				pub_dropped <= 8'd0;
				last_code <= 16'd0;
				pend <= 1'b0;
			end
		end
		else if (quiesce_pending) begin
			if (!ddram_busy) begin
				quiesce_pending <= 1'b0;
				ddram_we <= 1'b0;
				wstate <= W_MAGIC;
				written <= 32'd0;
				event_count <= 32'd0;
				dropped_count <= 8'd0;
				pub_dropped <= 8'd0;
				last_code <= 16'd0;
				pend <= 1'b0;
			end
		end
		else begin
			if (hit) begin
				event_count <= event_count + 1'd1;
				last_code <= hit_code;
				if (!pend) begin
					pend <= 1'b1;
					rec_a <= capture_a;
					rec_b <= capture_b;
				end
				else if (dropped_count != 8'hff)
					dropped_count <= dropped_count + 1'd1;
			end
			if (!ddram_busy) begin
				ddram_we <= 1'b0;
				case (wstate)
					W_MAGIC: begin
						ddram_addr <= BASE_WORD;
						ddram_din <= {8'd0, RING_ENTRIES, 16'd2, MAGIC};
						ddram_we <= 1'b1;
						wstate <= W_INIT_HDR;
					end
					W_INIT_HDR: begin
						ddram_addr <= BASE_WORD + 29'd1;
						ddram_din <= 64'd0;
						ddram_we <= 1'b1;
						pub_dropped <= 8'd0;
						wstate <= W_IDLE;
					end
					W_IDLE:
						if (pend)
							wstate <= W_RECA;
						else if (pub_dropped != dropped_count)
							wstate <= W_REPUB;
					W_RECA: begin
						ddram_addr <= (BASE_WORD + 29'd2) + slot_off;
						ddram_din <= rec_a;
						ddram_we <= 1'b1;
						wstate <= W_RECB;
					end
					W_RECB: begin
						ddram_addr <= (BASE_WORD + 29'd3) + slot_off;
						ddram_din <= rec_b;
						ddram_we <= 1'b1;
						wstate <= W_HDR;
					end
					W_HDR: begin
						ddram_addr <= BASE_WORD + 29'd1;
						ddram_din <= {24'd0, dropped_count, written + 32'd1};
						ddram_we <= 1'b1;
						written <= written + 1'd1;
						pub_dropped <= dropped_count;
						pend <= 1'b0;
						wstate <= W_IDLE;
					end
					W_REPUB: begin
						ddram_addr <= BASE_WORD + 29'd1;
						ddram_din <= {24'd0, dropped_count, written};
						ddram_we <= 1'b1;
						pub_dropped <= dropped_count;
						wstate <= W_IDLE;
					end
					default: wstate <= W_IDLE;
				endcase
			end
		end
endmodule
