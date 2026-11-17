`default_nettype wire
module plus_load_model (
	clk,
	status,
	fn_toggle,
	cpr_apply,
	cpr_image_valid,
	sna_download,
	sna_header_wr,
	sna_addr,
	sna_data,
	sna_prepare,
	plus_model,
	status_in,
	status_set
);
	input clk;
	input [63:0] status;
	input fn_toggle;
	input cpr_apply;
	input cpr_image_valid;
	input sna_download;
	input sna_header_wr;
	input [7:0] sna_addr;
	input [7:0] sna_data;
	input sna_prepare;
	output wire [1:0] plus_model;
	output reg [63:0] status_in = 64'd0;
	output reg status_set = 1'b0;
	reg [1:0] selected = 2'd0;
	reg model_pending = 1'b0;
	reg sound_pending = 1'b0;
	reg sound = 1'b0;
	reg publish_pending = 1'b0;
	reg request_in_flight = 1'b0;
	localparam [63:0] OWNED_FIELDS = ((64'h0000000000000003 << 33) | (64'h0000000000000001 << 32)) | (64'h0000000000000001 << 20);
	reg old_fn = 1'b0;
	reg old_sna_download = 1'b0;
	reg [7:0] sna_version = 8'd0;
	reg [1:0] sna_plus_model = 2'd0;
	wire fn_edge = fn_toggle && !old_fn;
	wire select_sna = ((sna_prepare && !sna_download) && (sna_version >= 8'd3)) && (sna_plus_model != 2'd0);
	wire select_cpr = (cpr_apply && cpr_image_valid) && (plus_model == 2'd0);
	assign plus_model = (model_pending ? selected : status[34:33]);
	wire effective_sound = (sound_pending ? sound : status[20]);
	wire [63:0] effective_status = {status[63:35], plus_model, 1'b0, status[31:21], effective_sound, status[19:0]} & ~((64'h0000000000000001 << 38) | 64'h0000000000000001);
	always @(posedge clk) begin
		old_fn <= fn_toggle;
		old_sna_download <= sna_download;
		if (sna_download && !old_sna_download) begin
			sna_version <= 8'd0;
			sna_plus_model <= 2'd0;
		end
		if (sna_header_wr) begin
			if (sna_addr == 8'h10)
				sna_version <= sna_data;
			if (sna_addr == 8'h6d)
				case (sna_data)
					8'd4: sna_plus_model <= 2'd2;
					8'd5: sna_plus_model <= 2'd3;
					8'd6: sna_plus_model <= 2'd1;
					default: sna_plus_model <= 2'd0;
				endcase
		end
		if (request_in_flight && ((status & OWNED_FIELDS) == (status_in & OWNED_FIELDS)))
			request_in_flight <= 1'b0;
		if ((!request_in_flight && !publish_pending) && !status_set) begin
			if (model_pending && (status[34:33] == selected))
				model_pending <= 1'b0;
			if (sound_pending && (status[20] == sound))
				sound_pending <= 1'b0;
		end
		status_set <= 1'b0;
		if ((publish_pending && !status_set) && !request_in_flight) begin
			status_in <= effective_status;
			status_set <= 1'b1;
			request_in_flight <= 1'b1;
			publish_pending <= 1'b0;
		end
		if (fn_edge) begin
			sound <= ~effective_sound;
			sound_pending <= 1'b1;
			publish_pending <= 1'b1;
		end
		if (select_sna || select_cpr) begin
			selected <= (select_sna ? sna_plus_model : 2'd2);
			model_pending <= 1'b1;
			publish_pending <= 1'b1;
		end
	end
endmodule
