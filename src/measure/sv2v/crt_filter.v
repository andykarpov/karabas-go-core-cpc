module crt_filter (
	CLK,
	CE_4,
	HSYNC_I,
	VSYNC_I,
	HSYNC_O,
	VSYNC_O,
	HBLANK,
	HBLANK_LIVE,
	VBLANK,
	SHIFT,
	EXTRA_BYTE,
	START_GEN,
	END_GEN,
	SYNC_OBSERVATION
);
	input CLK;
	input CE_4;
	input HSYNC_I;
	input VSYNC_I;
	output reg HSYNC_O;
	output reg VSYNC_O;
	output reg HBLANK;
	output wire HBLANK_LIVE;
	output reg VBLANK;
	output wire SHIFT;
	output reg EXTRA_BYTE;
	output reg START_GEN;
	output reg END_GEN;
	output wire [15:0] SYNC_OBSERVATION;
	wire resync = 1;
	reg hs4;
	reg shift;
	reg legacy_hsync;
	reg phase_epoch;
	reg phase_pair_valid;
	reg signed [10:0] phase_first;
	reg signed [10:0] phase_pending;
	reg signed [10:0] phase_active;
	reg [9:0] phase_age;
	reg [8:0] phase_period;
	initial begin
		phase_epoch = 0;
		phase_pair_valid = 0;
		phase_first = 0;
		phase_pending = 0;
		phase_active = 0;
		phase_age = 1023;
		phase_period = 0;
	end
	initial begin
		EXTRA_BYTE = 0;
		START_GEN = 0;
		END_GEN = 0;
	end
	reg [8:0] hSyncSize;
	reg hSyncReg;
	reg [1:0] syncs;
	assign SHIFT = shift ^ hs4;
	reg hsync;
	reg no_hsync;
	localparam [9:0] LIVE_HBLANK_REMAINDER = 10'd1022;
	reg live_hblank_ext;
	reg old_live_hsync;
	reg [9:0] live_hblank_count;
	initial begin
		live_hblank_ext = 0;
		old_live_hsync = 0;
		live_hblank_count = 0;
	end
	assign HBLANK_LIVE = (no_hsync ? HBLANK : HSYNC_I | live_hblank_ext);
	always @(posedge CLK) begin : liveblankgen
		old_live_hsync <= HSYNC_I;
		if ((~old_live_hsync & HSYNC_I) & (~live_hblank_ext || (live_hblank_count == 0))) begin
			live_hblank_ext <= 1;
			live_hblank_count <= LIVE_HBLANK_REMAINDER;
		end
		else if (live_hblank_ext) begin
			if (live_hblank_count == 0)
				live_hblank_ext <= 0;
			else
				live_hblank_count <= live_hblank_count - 1'd1;
		end
	end
	always @(posedge CLK) begin : hsyncgen
		reg [15:0] dcnt;
		reg [10:0] hsz;
		reg [10:0] hcnt;
		reg old_vsync;
		reg old_hsync;
		reg no_hsync_next;
		if (CE_4) begin
			if (&dcnt) begin
				no_hsync_next <= 1;
				if (|hsz)
					no_hsync <= 1;
			end
			else
				dcnt <= dcnt + 1'd1;
			old_hsync <= HSYNC_I;
			if (~old_hsync & HSYNC_I) begin
				dcnt <= 0;
				if (!no_hsync)
					hsz <= dcnt[10:0];
				else if (!(|hsz)) begin
					hsz <= dcnt[10:0];
					hsync <= 1;
					hcnt <= 0;
				end
			end
			if (no_hsync && |hsz) begin
				hcnt <= hcnt + 1'd1;
				if (hcnt == 13)
					hsync <= 0;
				if (hcnt == hsz) begin
					hsync <= 1;
					hcnt <= 0;
				end
			end
			old_vsync <= VSYNC_I;
			if (~old_vsync & VSYNC_I) begin
				no_hsync <= no_hsync_next;
				no_hsync_next <= 0;
				hsz <= 0;
			end
		end
	end
	reg hsync_mask;
	initial hsync_mask = 0;
	always @(posedge CLK) begin : hsyncfilt
		reg old_hsync;
		reg [8:0] line_time;
		if (CE_4) begin
			old_hsync <= HSYNC_I;
			if (hsync_mask) begin
				if (~&line_time)
					line_time <= line_time + 1'd1;
				if (!HSYNC_I & (line_time >= 190))
					hsync_mask <= 0;
			end
			if ((HSYNC_I & ~old_hsync) & !hsync_mask)
				line_time <= 0;
			if ((~HSYNC_I & old_hsync) & !hsync_mask)
				hsync_mask <= 1;
		end
	end
	wire hsync_i = (no_hsync ? hsync : HSYNC_I & ~hsync_mask);
	reg rgb_meta_old_hs;
	reg rgb_meta_open;
	reg rgb_meta_real;
	reg [5:0] rgb_meta_width;
	initial begin
		rgb_meta_old_hs = 0;
		rgb_meta_open = 0;
		rgb_meta_real = 0;
		rgb_meta_width = 0;
	end
	always @(posedge CLK) begin : rgbmetadata
		if (CE_4) begin
			rgb_meta_old_hs <= hsync_i;
			if (!rgb_meta_old_hs && hsync_i) begin
				rgb_meta_open <= 1;
				rgb_meta_width <= 6'd1;
				rgb_meta_real <= !no_hsync;
				if (!no_hsync)
					START_GEN <= ~START_GEN;
			end
			else if ((rgb_meta_open && hsync_i) && !(&rgb_meta_width))
				rgb_meta_width <= rgb_meta_width + 1'd1;
			if (no_hsync)
				rgb_meta_real <= 0;
			if ((rgb_meta_old_hs && !hsync_i) && rgb_meta_open) begin
				EXTRA_BYTE <= (rgb_meta_real && !no_hsync) && (rgb_meta_width == 6'd16);
				END_GEN <= ~END_GEN;
				rgb_meta_open <= 0;
				rgb_meta_real <= 0;
			end
		end
	end
	assign SYNC_OBSERVATION = {syncs, hSyncReg, hsync_mask, no_hsync, SHIFT, hs4, hSyncSize};
	always @(posedge CLK) begin : syncgen
		reg old_hsync;
		reg old_vsync;
		reg old_vs;
		reg [8:0] hSyncCount;
		reg [9:0] hSyncCount2x;
		reg [3:0] vSyncCount;
		reg [8:0] vSyncFlt;
		integer phase_value;
		integer phase_sum;
		integer phase_effective;
		reg phase_anchor;
		localparam HFLT_SZ = 200;
		localparam VFLT_SZ = 260;
		if (CE_4) begin
			old_hsync <= hsync_i;
			if (resync) begin
				if (~&hSyncCount)
					hSyncCount = hSyncCount + 1'd1;
				if (~old_hsync & hsync_i)
					old_vs <= VSYNC_I;
				if ((((~old_vs & VSYNC_I) & ~old_hsync) & hsync_i) || (hSyncCount >= hSyncSize)) begin
					hSyncCount = 0;
					if (~old_hsync & hsync_i)
						hSyncReg <= 1;
				end
				if (~&hSyncCount2x)
					hSyncCount2x = hSyncCount2x + 1'd1;
				if (~old_hsync & hsync_i) begin
					if (~VSYNC_I & ~&syncs)
						syncs = syncs + 1'd1;
					if (VSYNC_I)
						{syncs, hSyncCount2x} = 0;
					if (syncs == 2)
						hSyncSize <= hSyncCount2x[9:1];
				end
			end
			else if (hSyncCount < HFLT_SZ)
				hSyncCount = hSyncCount + 1'd1;
			else if (~old_hsync & hsync_i) begin
				hSyncCount = 0;
				hSyncReg <= 1;
			end
			if ((old_hsync & ~hsync_i) & hSyncReg) begin
				hSyncReg <= 0;
				if (hSyncCount > 28)
					hs4 <= 0;
				if ((hSyncCount >= 15) && (hSyncCount < 23)) begin
					if (hSyncCount == 15)
						hs4 <= 1;
					shift <= 1;
				end
			end
			if (hSyncCount == 8) begin
				legacy_hsync <= 1;
				shift <= 0;
				old_vsync <= VSYNC_I;
				if (~&vSyncFlt)
					vSyncFlt <= vSyncFlt + 1'd1;
				if (VSYNC_I) begin
					if (~old_vsync && (vSyncFlt > VFLT_SZ)) begin
						vSyncCount = 0;
						vSyncFlt <= 0;
					end
					else if (~&vSyncCount)
						vSyncCount = vSyncCount + 1'd1;
				end
				if (vSyncCount == 1)
					VSYNC_O <= 1;
				if (!vSyncCount || (vSyncCount == 3))
					VSYNC_O <= 0;
			end
			if (~VSYNC_I)
				VSYNC_O <= 0;
			if (hSyncCount == 24)
				legacy_hsync <= 0;
			phase_anchor = ((~old_vs & VSYNC_I) & ~old_hsync) & hsync_i;
			phase_value = $signed({23'd0, hSyncCount});
			if (phase_value > ($signed({23'd0, hSyncSize}) >>> 1))
				phase_value = phase_value - $signed({23'd0, hSyncSize});
			phase_sum = $signed({{21 {phase_first[10]}}, phase_first}) + phase_value;
			phase_effective = $signed({{21 {phase_active[10]}}, phase_active});
			if (hSyncCount == 0) begin
				phase_effective = $signed({{21 {phase_pending[10]}}, phase_pending});
				phase_active <= phase_pending;
			end
			if (phase_age != 1023)
				phase_age <= phase_age + 1'd1;
			if ((no_hsync || (hSyncSize < 32)) || (hSyncSize != phase_period)) begin
				phase_epoch <= 0;
				phase_pair_valid <= 0;
				phase_pending <= 0;
			end
			if (phase_anchor) begin
				phase_epoch <= !no_hsync;
				phase_pair_valid <= 0;
				phase_pending <= 0;
				phase_active <= 0;
				phase_effective = 0;
				phase_period <= hSyncSize;
			end
			if (~old_hsync & hsync_i) begin
				phase_age <= 0;
				if (((((phase_epoch && !phase_anchor) && !no_hsync) && (hSyncSize >= 32)) && (phase_period == hSyncSize)) && (syncs == 3)) begin
					if ((((phase_value >= -8) && (phase_value <= 8)) && ((phase_age + 1) >= (hSyncSize - 16))) && ((phase_age + 1) <= (hSyncSize + 16))) begin
						if (!phase_pair_valid) begin
							phase_first <= phase_value[10:0];
							phase_pair_valid <= 1;
						end
						else begin
							phase_pair_valid <= 0;
							if ((phase_sum % 2) == 0)
								phase_pending <= phase_sum[11:1];
							else
								phase_pending <= 0;
						end
					end
					else begin
						phase_epoch <= 0;
						phase_pair_valid <= 0;
						phase_pending <= 0;
					end
				end
				else begin
					phase_pair_valid <= 0;
					phase_pending <= 0;
				end
			end
			if ($signed({23'd0, hSyncCount}) == (32'sd8 + phase_effective))
				HSYNC_O <= 1;
			if ($signed({23'd0, hSyncCount}) == (32'sd24 + phase_effective))
				HSYNC_O <= 0;
		end
	end
	always @(posedge CLK) begin : blankgen
		localparam BEGIN_VBORDER = 30;
		localparam END_VBORDER = 302;
		localparam BEGIN_HBORDER = 49;
		localparam END_HBORDER = 241;
		reg old_vs;
		reg old_hs;
		reg old_line;
		reg [8:0] vborder;
		reg [8:0] hborder;
		if (CE_4) begin
			if (~&hborder)
				hborder <= hborder + 1'd1;
			old_hs <= HSYNC_O;
			if (~old_hs & HSYNC_O) begin
				hborder <= 0;
				HBLANK <= 1;
			end
			old_line <= legacy_hsync;
			if (~old_line & legacy_hsync) begin
				if (~&vborder)
					vborder <= vborder + 1'd1;
				old_vs <= VSYNC_O;
				if (~old_vs & VSYNC_O) begin
					vborder <= 0;
					VBLANK <= 1;
				end
			end
			if (hborder == BEGIN_HBORDER)
				HBLANK <= 0;
			if (hborder == BEGIN_HBORDER) begin
				if (vborder == BEGIN_VBORDER)
					VBLANK <= 0;
			end
			if (hborder == END_HBORDER)
				HBLANK <= 1;
			if (hborder == END_HBORDER) begin
				if (vborder == END_VBORDER)
					VBLANK <= 1;
			end
		end
	end
endmodule
