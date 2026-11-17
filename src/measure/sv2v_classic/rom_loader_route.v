module rom_loader_route (
	ioctl_index,
	ioctl_addr,
	page,
	rom_active,
	addr_valid,
	initial_bank,
	dest_a_hi,
	promote_bank0_to_bank1
);
	input [7:0] ioctl_index;
	input [24:14] ioctl_addr;
	input [8:0] page;
	output wire rom_active;
	output wire addr_valid;
	output wire [1:0] initial_bank;
	output wire [8:0] dest_a_hi;
	output wire promote_bank0_to_bank1;
	assign rom_active = (ioctl_index[4:0] < 5'd4) || (ioctl_index == 8'd7);
	assign promote_bank0_to_bank1 = (ioctl_index[7:6] == 2'b01) || (ioctl_index[5:0] != 6'd0);
	reg valid;
	reg [1:0] bank;
	reg [8:0] a_hi;
	always @(*)
		if (ioctl_index != 8'd0) begin
			valid = 1'b1;
			bank = (ioctl_index == 8'd7 ? 2'd2 : {1'b0, &ioctl_index[7:6]});
			a_hi = {page[8], page[7:0] + ioctl_addr[21:14]};
		end
		else begin
			case (ioctl_addr[24:14])
				11'd0, 11'd4: begin
					a_hi = 9'h000;
					valid = 1'b1;
				end
				11'd1, 11'd5: begin
					a_hi = 9'h100;
					valid = 1'b1;
				end
				11'd2, 11'd6: begin
					a_hi = 9'h107;
					valid = 1'b1;
				end
				11'd3, 11'd7: begin
					a_hi = 9'h0ff;
					valid = 1'b1;
				end
				11'd8: begin
					a_hi = 9'h000;
					valid = 1'b1;
				end
				11'd9: begin
					a_hi = 9'h100;
					valid = 1'b1;
				end
				default: begin
					a_hi = 9'h000;
					valid = 1'b0;
				end
			endcase
			case (ioctl_addr[24:14])
				11'd0, 11'd1, 11'd2, 11'd3: bank = 2'd0;
				11'd4, 11'd5, 11'd6, 11'd7: bank = 2'd1;
				11'd8, 11'd9: bank = 2'd2;
				default: bank = 2'd0;
			endcase
		end
	assign addr_valid = valid;
	assign initial_bank = bank;
	assign dest_a_hi = a_hi;
endmodule
