module casgen_sync (
	clk,
	cen_16,
	RESET_N,
	M1_N,
	PHI_N,
	MREQ_N,
	S,
	CAS_N
);
	input clk;
	input cen_16;
	input RESET_N;
	input M1_N;
	input PHI_N;
	input MREQ_N;
	input [7:0] S;
	output wire CAS_N;
	reg U708;
	reg M1_N_d;
	reg MREQ_N_d;
	always @(posedge clk) begin : edge_detect
		M1_N_d <= M1_N;
		MREQ_N_d <= MREQ_N;
	end
	always @(posedge clk or negedge RESET_N) begin : mask_refresh
		if (!RESET_N)
			U708 <= 1;
		else if (~M1_N_d & M1_N)
			U708 <= 0;
		else if (~MREQ_N_d & MREQ_N)
			U708 <= 1;
	end
	reg S_d1_a;
	reg S_d2_a;
	always @(posedge clk)
		if (cen_16) begin
			S_d1_a <= ((~S[4] & S[5]) | (~S[3] & S[1])) | (S[1] & S[7]);
			S_d2_a <= S_d1_a;
		end
	wire U710 = ((~U708 | MREQ_N) | ~S[4]) | S[5];
	wire U712;
	rslatch #(.PRIO_SET(0)) u712_l(
		.clock(clk),
		.s(S_d1_a),
		.r(~(S[2] & U710)),
		.q(U712)
	);
	assign CAS_N = (U712 | S_d1_a) | S_d2_a;
endmodule
