// sim_cpc: cpc_core (tb_cpc.v) in verilator. Loads roms/boot.rom as the ROM of the .kg (load kind
// 0, packets of 512 bytes while ld_ready, a byte per 16 clocks as the mcu sends them), runs the
// given time of the machine and writes frames of the raw 15 kHz picture (16 MHz pixels, 1024 per
// line, blank areas dark grey) as PPM.
//   sim_cpc [--ms N] [--ppm PREFIX] [--every N] [--model 0|1|2] [--crtc 0|1]
//           [--key MS:CODE[:E]]... (a PS/2 set 2 key pressed at MS for 100 ms, E = extended)
//           [--geometry] (prints the line / frame lengths and the picture window, also of the output)
//           [--ppm2 PREFIX] (the 1024 x 624 frames of cpc_video_out, de outside grey, syncs blue)
#include "Vtb_cpc.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <string>
#include <vector>

static Vtb_cpc *tb;
static uint64_t clocks = 0;

static void tick() {
	tb->clk_sys = 0;
	tb->eval();
	tb->clk_sys = 1;
	tb->eval();
	clocks++;
}

int main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	double ms = 1500;
	std::string ppm;
	int every = 25, model = 0, crtc = 0;
	bool geometry = false;
	std::string ppm2;
	bool old_pix = false, ohs2 = false, ovs2 = false;
	int hc2 = 0, vl2 = 0, ll2 = 0, frames2 = 0, dx0 = 99999, dx1 = -1, dy0 = 99999, dy1 = -1, x0 = 99999, x1 = -1, y0 = 99999, y1 = -1;
	std::vector<uint8_t> frame2(1024 * 640 * 3, 0);
	struct Key { uint64_t at; uint8_t code; bool ext; };
	std::vector<Key> keys;
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--ms") && i + 1 < argc) ms = atof(argv[++i]);
		else if (!strcmp(argv[i], "--ppm") && i + 1 < argc) ppm = argv[++i];
		else if (!strcmp(argv[i], "--every") && i + 1 < argc) every = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--model") && i + 1 < argc) model = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--crtc") && i + 1 < argc) crtc = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--geometry")) geometry = true;
		else if (!strcmp(argv[i], "--ppm2") && i + 1 < argc) ppm2 = argv[++i];
		else if (!strcmp(argv[i], "--key") && i + 1 < argc) {
			Key k; unsigned c; double at; char e = 0;
			if (sscanf(argv[++i], "%lf:%x:%c", &at, &c, &e) < 2) { fprintf(stderr, "bad --key\n"); return 1; }
			k.at = (uint64_t)(at * 64000.0); k.code = c; k.ext = e == 'E';
			keys.push_back(k);
		}
	}

	FILE *f = fopen("roms/boot.rom", "rb");
	if (!f) { perror("roms/boot.rom"); return 1; }
	std::vector<uint8_t> rom(1 << 20);
	size_t rom_len = fread(rom.data(), 1, rom.size(), f);
	fclose(f);
	rom.resize(rom_len);

	tb = new Vtb_cpc;
	tb->areset = 1;
	tb->sw_model = model;
	tb->sw_crtc = crtc;
	for (int i = 0; i < 64; i++) tick();
	tb->areset = 0;

	// the load: START, DATA packets, END as kg_l2_load gives them
	size_t pos = 0;
	int pkt_left = 0, gap = 0;
	bool load_done = false;
	tb->ld_kind = 0;
	tb->ld_active = 1;
	tb->ld_start = 1;
	tick();
	tb->ld_start = 0;

	// PS/2 bytes to send, one per 2000 clocks (the mcu sends a key as one packet)
	std::deque<std::pair<uint64_t, uint8_t>> ps2;
	for (auto &k : keys) {
		uint64_t t = k.at;
		if (k.ext) ps2.push_back({t, 0xE0});
		ps2.push_back({t, k.code});
		t += 6400000;
		if (k.ext) ps2.push_back({t, 0xE0});
		ps2.push_back({t, 0xF0});
		ps2.push_back({t, k.code});
	}
	uint64_t next_ps2 = 0;

	// the picture
	const int W = 1024, H = 320;
	std::vector<uint8_t> frame(W * H * 3, 0);
	int x = 0, y = 0, frames = 0;
	bool old_hs = false, old_vs = false;
	int line_len = 0, last_line_len = 0, lines = 0;
	int pic_x0 = W, pic_x1 = -1, pic_y0 = H, pic_y1 = -1;
	uint64_t end = (uint64_t)(ms * 64000.0);
	uint64_t load_end_clock = 0;

	while (clocks < end) {
		// loader
		tb->ld_wr = 0;
		if (!load_done) {
			if (gap > 0) gap--;
			else if (pkt_left == 0 && pos < rom.size()) {
				if (tb->ld_ready) pkt_left = 512;
			}
			else if (pkt_left > 0) {
				tb->ld_wr = 1;
				tb->ld_addr = pos;
				tb->ld_data = rom[pos];
				pos++;
				pkt_left = pos < rom.size() ? pkt_left - 1 : 0;
				gap = 15;
			}
			if (pos >= rom.size() && pkt_left == 0 && gap == 0) {
				tb->ld_active = 0;
				load_done = true;
			}
		}
		if (load_done && !load_end_clock && !tb->loading) {
			load_end_clock = clocks;
			printf("load done at %.1f ms\n", clocks / 64000.0);
		}
		// keys
		tb->ps2_wr = 0;
		if (!ps2.empty() && clocks >= ps2.front().first && clocks >= next_ps2) {
			tb->ps2_code = ps2.front().second;
			tb->ps2_wr = 1;
			ps2.pop_front();
			next_ps2 = clocks + 2000;
		}

		tick();

		// the output of cpc_video_out at each rising edge of clk_pix: its frame, de and the non-black
		// picture inside it; --geometry prints them, --ppm2 writes the 1024 x 624 frames
		if (tb->clk_pix && !old_pix) {
			bool shs = tb->vo_hs, svs = tb->vo_vs;
			if (svs && !ovs2) {
				frames2++;
				if (geometry && frames2 >= 3 && frames2 <= 6)
					printf("out frame %d: %d lines, line %d, de x %d..%d y %d..%d, picture x %d..%d y %d..%d\n",
					       frames2, vl2, ll2, dx0, dx1, dy0, dy1, x0, x1, y0, y1);
				if (!ppm2.empty() && frames2 % every == 0) {
					char name[512];
					snprintf(name, sizeof name, "%s%04d.ppm", ppm2.c_str(), frames2);
					FILE *o = fopen(name, "wb");
					fprintf(o, "P6 1024 640 255\n");
					fwrite(frame2.data(), 1, frame2.size(), o);
					fclose(o);
				}
				vl2 = 0; dx0 = x0 = 99999; dx1 = x1 = -1; dy0 = y0 = 99999; dy1 = y1 = -1;
			}
			if (shs && !ohs2) { ll2 = hc2; hc2 = 0; vl2++; }
			uint32_t c = tb->vo_rgb;
			if (tb->vo_de) {
				if (hc2 < dx0) dx0 = hc2; if (hc2 > dx1) dx1 = hc2;
				if (vl2 < dy0) dy0 = vl2; if (vl2 > dy1) dy1 = vl2;
				if (c) {
					if (hc2 < x0) x0 = hc2; if (hc2 > x1) x1 = hc2;
					if (vl2 < y0) y0 = vl2; if (vl2 > y1) y1 = vl2;
				}
			}
			if (hc2 < 1024 && vl2 < 640) {
				uint8_t *p = &frame2[(vl2 * 1024 + hc2) * 3];
				p[0] = c >> 16; p[1] = c >> 8; p[2] = c;
				if (!tb->vo_de) { p[0] = p[1] = p[2] = 40; }
				if (shs || svs) { p[0] = 0; p[1] = 0; p[2] = 96; }
			}
			hc2++;
			ohs2 = shs; ovs2 = svs;
		}
		old_pix = tb->clk_pix;

		if (tb->vid_ce) {
			bool hs = tb->vid_hs, vs = tb->vid_vs;
			if (hs && !old_hs) {
				last_line_len = line_len;
				line_len = 0;
				x = 0;
				y++;
			}
			if (vs && !old_vs) {
				frames++;
				if (geometry && frames >= 3 && frames <= 4)
					printf("frame %d: %d lines, line %d pixels, picture x %d..%d y %d..%d\n", frames, y,
					       last_line_len, pic_x0, pic_x1, pic_y0, pic_y1);
				if (!ppm.empty() && frames % every == 0) {
					char name[512];
					snprintf(name, sizeof name, "%s%04d.ppm", ppm.c_str(), frames);
					FILE *o = fopen(name, "wb");
					fprintf(o, "P6 %d %d 255\n", W, H);
					fwrite(frame.data(), 1, frame.size(), o);
					fclose(o);
					printf("frame %d at %.1f ms -> %s\n", frames, clocks / 64000.0, name);
				}
				lines = y;
				y = 0;
				pic_x0 = W; pic_x1 = -1; pic_y0 = H; pic_y1 = -1;
			}
			old_hs = hs;
			old_vs = vs;
			if (x < W && y < H) {
				uint8_t *p = &frame[(y * W + x) * 3];
				bool blank = tb->vid_hbl || tb->vid_vbl;
				if (blank) { p[0] = p[1] = p[2] = 24; }
				else {
					p[0] = tb->vid_r; p[1] = tb->vid_g; p[2] = tb->vid_b;
					if (x < pic_x0) pic_x0 = x;
					if (x > pic_x1) pic_x1 = x;
					if (y < pic_y0) pic_y0 = y;
					if (y > pic_y1) pic_y1 = y;
				}
				if (hs || vs) { p[0] = 0; p[1] = 0; p[2] = 96; }
			}
			x++;
			line_len++;
		}
	}
	printf("%.1f ms, %d frames, %d lines in the last frame\n", clocks / 64000.0, frames, lines);
	delete tb;
	return 0;
}
