`default_nettype wire
module dandanator_loader_bounds (
	dan_download,
	ioctl_wr,
	ioctl_addr,
	write_accepted
);
	input dan_download;
	input ioctl_wr;
	input [24:0] ioctl_addr;
	output wire write_accepted;
	assign write_accepted = (dan_download && ioctl_wr) && (ioctl_addr < 25'h0080000);
endmodule
