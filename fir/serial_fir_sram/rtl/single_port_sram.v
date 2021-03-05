
// pro-gen:start here,coding before this line
module single_port_sram #(
	parameter DWIDTH = 8,
	parameter AWIDTH = 6
) (
	input clk,
	input rst_n,
	input [AWIDTH - 1 : 0] address,
	input write_req,
	input [DWIDTH - 1 : 0] write_data,
	output [DWIDTH - 1 : 0] read_data
);

// link

// this on link:
	// 
// pro-gen:stop here,coding after this line

reg [DWIDTH - 1:0] mem [2 ** AWIDTH - 1:0];

genvar i;
generate
	for (i = 0; i < 2 ** AWIDTH; i = i + 1) begin
		always @ (posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				mem[i] <= {DWIDTH{1'b0}};
			end else if (i == address && write_req) begin
				mem[i] <= write_data;
			end
		end
	end
endgenerate

assign read_data = mem[address];

endmodule

