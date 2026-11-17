`timescale 1ns / 1ps
// u765 (rtl/sv2v) behind cpc_sd_sdc, against a model of the file mounter of kg_mcu2 (the contract of
// img_sdc: sdc_busy when a request is taken, the 512 bytes of a read as sdc_byte_in_strobe / addr /
// data, the bytes of a write taken from sdc_byte_out_data OUT_LATENCY (+olat, default 3) clocks after sdc_byte_addr,
// then sdc_done). The disk is a .dsk file in an array. The CPU side: FDC commands through the data /
// status registers as the CPC firmware does (Specify, Recalibrate, Sense Interrupt, Read ID, Read Data
// of sector C1 compared with the file, Write Data of sector C2 and a Read Data of it back).
//   sim/run_disk.sh [file.dsk]   (verilator --binary --timing; PASS / ERROR lines, "tb_disk: N errors")
module tb_disk;

reg clk = 1'b0;
always #7.8125 clk = ~clk;   // 64 MHz

reg [2:0] cediv = 3'd0;
reg ce = 1'b0;               // 8 MHz, as ce_u765
always @(posedge clk) begin
	cediv <= cediv + 3'd1;
	ce <= cediv == 3'd0;
end

reg reset = 1'b1;
reg fast = 1'b0;
reg [7:0] rd_cmd = 8'h66;   // Read Data as AMSDOS sends it (MFM, SK); +cmd46 for 46   // +fast: no rotation delays (the board runs with 0)
reg a0 = 1'b0, nRD = 1'b1, nWR = 1'b1;
reg [7:0] din = 8'd0;
wire [7:0] dout;

wire [31:0] sd_lba;
wire [1:0] sd_rd, sd_wr, sd_ack, img_mounted;
wire [8:0] sd_buff_addr;
wire [7:0] sd_buff_dout, sd_buff_din;
wire sd_buff_wr, img_readonly;
wire [63:0] img_size;

reg [7:0] sdc_img_mounted = 8'd0;
reg [63:0] sdc_img_size = 64'd0;
wire [7:0] sdc_rd, sdc_wr;
wire [31:0] sdc_sector;
reg sdc_busy = 1'b0, sdc_done = 1'b0, sdc_byte_in_strobe = 1'b0;
reg [2:0] sdc_slot = 3'd0;
reg [8:0] sdc_byte_addr = 9'd0;
reg [7:0] sdc_byte_in_data = 8'd0;
wire [7:0] sdc_byte_out_data;

u765 fdc (
	.reset(reset), .clk_sys(clk), .ce(ce), .fast(fast),
	.a0(a0), .ready({ 1'b0, |img_size_q }), .motor(2'b11), .available(2'b11),
	.nRD(nRD), .nWR(nWR), .din(din), .dout(dout),
	.img_mounted(img_mounted), .img_size(img_size[31:0]), .img_wp(img_readonly),
	.sd_lba(sd_lba), .sd_rd(sd_rd), .sd_wr(sd_wr), .sd_ack(|sd_ack),
	.sd_buff_addr(sd_buff_addr), .sd_buff_dout(sd_buff_dout), .sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr), .snap_pcn_a(), .snap_pcn_b()
);

// cpc_emu: u765_ready from the size at the mount
reg [63:0] img_size_q = 64'd0;
always @(posedge clk) if (img_mounted[0]) img_size_q <= img_size;

cpc_sd_sdc adapter (
	.clk(clk), .reset(reset),
	.sd_lba(sd_lba), .sd_rd(sd_rd), .sd_wr(sd_wr), .sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr), .sd_buff_dout(sd_buff_dout), .sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr), .img_mounted(img_mounted), .img_size(img_size), .img_readonly(img_readonly),
	.sdc_img_mounted(sdc_img_mounted), .sdc_img_size(sdc_img_size), .img_wp(8'd0),
	.sdc_rd(sdc_rd), .sdc_wr(sdc_wr), .sdc_sector(sdc_sector), .sdc_busy(sdc_busy), .sdc_done(sdc_done),
	.sdc_slot(sdc_slot), .sdc_byte_in_strobe(sdc_byte_in_strobe), .sdc_byte_addr(sdc_byte_addr),
	.sdc_byte_in_data(sdc_byte_in_data), .sdc_byte_out_data(sdc_byte_out_data)
);

// ------------------------------------------------------------------ the mounter model

reg [7:0] disk [0:1048575];
integer disk_len, fd, k, errors = 0, reads = 0, writes = 0, lat = 200, olat = 3;   // +olat=N: IMG_OUT_LATENCY of the top; +lat=N: clocks before a read is served (the real mounter: 5..15 ms = 320k..960k)
reg [8*256-1:0] dskname;

task mounter;
	integer n, lba, i, slot;
	begin
		forever begin
			@(posedge clk);
			if (sdc_rd[1:0] != 2'b00 || sdc_wr[1:0] != 2'b00) begin
				slot = sdc_rd[0] || sdc_wr[0] ? 0 : 1;
				n = sdc_wr[slot];
				lba = sdc_sector;
				sdc_slot <= slot;
				sdc_busy <= 1'b1;
				if (n) begin
					// as kg_l2_img (S_CADDR / S_CDATA): the address out, the byte taken at the edge
					// OUT_LATENCY clocks later (its value just before that edge)
					for (i = 0; i < 512; i = i + 1) begin
						@(posedge clk);
						#1 sdc_byte_addr = i;    // after the edge, as a register of kg_l2_img
						repeat (olat - 1) @(posedge clk);
						@(negedge clk);
						disk[lba * 512 + i] = sdc_byte_out_data;
					end
					writes = writes + 1;
				end
				else begin
					repeat (lat) @(posedge clk);
					// as kg_l2_img (S_OADDR / S_ODATA): a byte every 3 clocks, sdc_done the clock after
					// the address state that sees 512
					for (i = 0; i < 512; i = i + 1) begin
						@(posedge clk);
						sdc_byte_in_strobe <= 1'b0;
						@(posedge clk);
						@(posedge clk);
						sdc_byte_addr <= i;
						sdc_byte_in_data <= (lba * 512 + i < disk_len) ? disk[lba * 512 + i] : 8'h00;
						sdc_byte_in_strobe <= 1'b1;
					end
					@(posedge clk);
					sdc_byte_in_strobe <= 1'b0;
					reads = reads + 1;
				end
				@(posedge clk);
				sdc_done <= 1'b1;
				sdc_busy <= 1'b0;
				@(posedge clk);
				sdc_done <= 1'b0;
			end
		end
	end
endtask

// ------------------------------------------------------------------ the CPU side

task io_wr(input reg addr0, input [7:0] d);
	begin
		@(posedge clk); a0 <= addr0; din <= d; nWR <= 1'b0;
		repeat (16) @(posedge clk);
		nWR <= 1'b1;
		repeat (16) @(posedge clk);
	end
endtask

task io_rd(input reg addr0, output [7:0] d);
	begin
		@(posedge clk); a0 <= addr0; nRD <= 1'b0;
		repeat (16) @(posedge clk);
		d = dout;
		nRD <= 1'b1;
		repeat (16) @(posedge clk);
	end
endtask

// wait for RQM with the given direction (DIO: 1 = FDC to CPU)
task wait_rqm(input reg dio);
	reg [7:0] msr;
	integer t;
	begin
		t = 0;
		msr = 8'h00;
		while (!(msr[7] && msr[6] == dio) && t < 4000000) begin
			io_rd(1'b0, msr);
			t = t + 1;
		end
		if (t >= 4000000) begin
			$display("ERROR: no RQM (dio %0d), MSR %02h", dio, msr);
			errors = errors + 1;
		end
	end
endtask

task cmd(input [7:0] b);
	begin
		wait_rqm(1'b0);
		io_wr(1'b1, b);
	end
endtask

task res(output [7:0] b);
	begin
		wait_rqm(1'b1);
		io_rd(1'b1, b);
	end
endtask

// the offset of sector R of track 0 side 0 in a .dsk / extended .dsk image
function integer sector_offset(input integer r);
	integer t, ns, s, off, len, ext;
	begin
		ext = disk[0] == "E";
		t = 256;                                 // track 0 info
		ns = disk[t + 8'h15];
		off = t + 256;
		sector_offset = -1;
		for (s = 0; s < ns; s = s + 1) begin
			len = ext ? (disk[t + 8'h18 + s * 8 + 6] | (disk[t + 8'h18 + s * 8 + 7] << 8)) : (128 << disk[t + 8'h14]);
			if (disk[t + 8'h18 + s * 8 + 2] == r && sector_offset < 0)
				sector_offset = off;
			off = off + len;
		end
	end
endfunction

task read_sector(input [7:0] r, input integer check_off, input [7:0] fill);
	reg [7:0] b;
	integer i, bad;
	begin
		cmd(rd_cmd); cmd(8'h00); cmd(8'h00); cmd(8'h00); cmd(r); cmd(8'h02); cmd(r); cmd(8'h2A); cmd(8'hFF);
		bad = 0;
		for (i = 0; i < 512; i = i + 1) begin
			res(b);
			if (check_off >= 0 ? b !== disk[check_off + i] : b !== fill) begin
				if (bad < 4) $display("ERROR: sector %02h byte %0d = %02h, want %02h", r, i, b,
				                      check_off >= 0 ? disk[check_off + i] : fill);
				bad = bad + 1;
			end
		end
		errors = errors + (bad != 0);
		// the CPC reads with EOT = R: the end is "abnormal" with End of Cylinder (ST0 4x, ST1 80)
		for (i = 0; i < 7; i = i + 1) begin
			res(b);
			if (i == 0) st0 = b;
			if (i == 1 && !(st0[7:6] == 2'b00 || (st0[7:6] == 2'b01 && b == 8'h80))) begin
				$display("ERROR: read %02h ST0 %02h ST1 %02h", r, st0, b);
				errors = errors + 1;
			end
		end
		if (bad == 0) $display("PASS read data %02h (512 bytes)", r);
	end
endtask

reg [7:0] b, st0, pcn;
integer i;
initial begin
	if ($test$plusargs("fast")) fast = 1'b1;
	if ($test$plusargs("cmd46")) rd_cmd = 8'h46;
	if ($value$plusargs("olat=%d", olat)) $display("tb_disk: write out latency %0d clocks", olat);
	if ($value$plusargs("lat=%d", lat)) $display("tb_disk: read latency %0d clocks", lat);
	if (!$value$plusargs("dsk=%s", dskname)) dskname = "rtl/amstrad/u765/test.dsk";
	fd = $fopen(dskname, "rb");
	if (fd == 0) begin $display("ERROR: no %0s", dskname); $finish; end
	disk_len = $fread(disk, fd);
	$fclose(fd);
	$display("tb_disk: %0s, %0d bytes", dskname, disk_len);
	fork mounter; join_none
	repeat (100) @(posedge clk);
	reset <= 1'b0;
	repeat (100) @(posedge clk);

	// mount drive A as the firmware does it (link_img_mount): an eject (size 0), then the image,
	// a link packet (a few us) apart
	@(posedge clk); sdc_img_size <= 64'd0; sdc_img_mounted <= 8'h01;
	@(posedge clk); sdc_img_mounted <= 8'h00;
	repeat (300) @(posedge clk);
	@(posedge clk); sdc_img_size <= disk_len; sdc_img_mounted <= 8'h01;
	@(posedge clk); sdc_img_mounted <= 8'h00;
	repeat (50000) @(posedge clk);
	if (reads == 0) begin $display("ERROR: no read after the mount"); errors = errors + 1; end
	else $display("PASS mount: %0d sector reads", reads);

	cmd(8'h03); cmd(8'hA1); cmd(8'h03);                 // Specify
	cmd(8'h07); cmd(8'h00);                             // Recalibrate drive 0
	st0 = 8'h00;
	for (i = 0; i < 100 && st0[5] == 1'b0; i = i + 1) begin
		repeat (2000) @(posedge clk);
		cmd(8'h08); res(st0); if (st0 != 8'h80) res(pcn);    // Sense Interrupt
	end
	if (st0[5] && pcn == 8'd0) $display("PASS recalibrate: ST0 %02h PCN %0d", st0, pcn);
	else begin $display("ERROR: recalibrate ST0 %02h PCN %0d", st0, pcn); errors = errors + 1; end

	cmd(8'h4A); cmd(8'h00);                             // Read ID
	for (i = 0; i < 7; i = i + 1) begin res(b); if (i == 0) st0 = b; if (i == 5) pcn = b; end
	if (st0[7:6] == 2'b00) $display("PASS read ID: ST0 %02h R %02h", st0, pcn);
	else begin $display("ERROR: read ID ST0 %02h", st0); errors = errors + 1; end

	// the directory as AMSDOS reads it: sectors 1..4 of track 0, one Read Data each
	for (k = 0; k < 4; k = k + 1)
		read_sector(disk[256 + 8'h18 + k * 8 + 2], sector_offset(disk[256 + 8'h18 + k * 8 + 2]), 8'h00);

	// Write Data: the second sector of the track with a pattern, then read it back
	k = disk[256 + 8'h18 + 8 + 2];
	cmd(8'h45); cmd(8'h00); cmd(8'h00); cmd(8'h00); cmd(k); cmd(disk[256 + 8'h18 + 8 + 3]); cmd(k); cmd(8'h2A); cmd(8'hFF);
	for (i = 0; i < 512; i = i + 1) begin wait_rqm(1'b0); io_wr(1'b1, (i * 7 + 1) & 8'hFF); end
	for (i = 0; i < 7; i = i + 1) begin res(b); if (i == 0) st0 = b; if (i == 1) pcn = b; end
	if ((st0[7:6] == 2'b00 || (st0[7:6] == 2'b01 && pcn == 8'h80)) && writes > 0) $display("PASS write data %02h: %0d sector writes", k, writes);
	else begin $display("ERROR: write ST0 %02h, %0d sector writes", st0, writes); errors = errors + 1; end
	k = sector_offset(k);
	for (i = 0; i < 512 && k >= 0; i = i + 1)
		if (disk[k + i] !== ((i * 7 + 1) & 8'hFF)) begin
			if (errors < 20) $display("ERROR: image byte %0d = %02h after the write", i, disk[k + i]);
			errors = errors + 1;
			i = 512;
		end

	$display("tb_disk: %0d errors", errors);
	$finish;
end

initial begin
	#3000000000;
	$display("ERROR: timeout");
	$display("tb_disk: %0d errors", errors + 1);
	$finish;
end

endmodule
