
// pro-gen:start here,coding before this line
module parallel_fir #(
	parameter DWIDTH = 8,
	parameter AWIDTH = 6,
	parameter WINLEN = 64,
	parameter OWIDTH = 22,
	parameter OSTART = 0
) (
	input clk,
	input rst_n,
	input cfg_valid,
	output reg cfg_busy,
	input [AWIDTH - 1 : 0] cfg_addr,
	input [DWIDTH - 1 : 0] cfg_data,
	input fir_din_valid,
	output reg fir_din_busy,
	input [DWIDTH - 1 : 0] fir_din_data,
	output fir_dout_valid,
	input fir_dout_busy,
	output [OWIDTH - 1 : 0] fir_dout_data
);

// link

// this on link:
	// 
// pro-gen:stop here,coding after this line

wire is_din = fir_din_valid && !fir_din_busy;
wire is_dout = fir_dout_valid && !fir_dout_busy;
wire is_dout_block = fir_dout_valid && fir_dout_busy;
wire is_din_block = is_din && is_dout_block;
wire is_cfg = cfg_valid && !cfg_busy;
// input port with block
reg block_sign;
reg [DWIDTH - 1:0]block_data;
wire [DWIDTH - 1:0] real_din;
wire real_din_valid;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		fir_din_busy <= 1'b0;
	end else if (is_din_block) begin
		fir_din_busy <= 1'b1;
	end else if (is_dout) begin
		fir_din_busy <= 1'b0;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		block_sign <= 1'b0;
	end else if (is_din_block) begin
		block_sign <= 1'b1;
	end else if (is_dout) begin
		block_sign <= 1'b0;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		block_data <= {DWIDTH{1'b0}};
	end else if (is_din_block) begin
		block_data <= fir_din_data;
	end
end
assign real_din = (block_sign)?block_data:fir_din_data;
assign real_din_valid = (is_din) || (block_sign && is_dout);
// data and weight
genvar di;
reg data_valid;
reg signed [DWIDTH - 1:0] din [WINLEN - 1:0];
reg signed [DWIDTH - 1:0] weight [WINLEN - 1:0];
generate
	for (di = 0; di < WINLEN ; di = di + 1) begin:proc_di
		wire [DWIDTH - 1:0] this_din;
		if (di == 0) begin
			assign this_din = real_din;
		end else begin
			assign this_din = din[di - 1];
		end
		always @ (posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				din[di] <= {DWIDTH{1'b0}};
			end else if (real_din_valid && !is_dout_block) begin
				din[di] <= this_din;
			end
		end
		always @ (posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				weight[di] <= {DWIDTH{1'b0}};
			end else if (is_cfg && di == cfg_addr) begin
				weight[di] <= cfg_data;
			end
		end
	end
endgenerate
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_valid <= 1'b0;
	end else if(real_din_valid && !is_dout_block)begin
		data_valid <= 1'b1; 
	end else if (!is_dout_block) begin
		data_valid <= 1'b0;
	end
end

// mul
genvar mi;
reg mul_outvalid;
reg signed [2 * DWIDTH - 1:0] mul_result [WINLEN - 1:0];
generate
	for (mi = 0; mi < WINLEN; mi = mi + 1) begin:proc_mi
		always @ (posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				mul_result[mi] <= {2*DWIDTH{1'b0}};
			end else if (data_valid && !is_dout_block) begin
				mul_result[mi] <= din[mi] * weight[mi];
			end
		end
	end
endgenerate
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mul_outvalid <= 1'b0;
	end else if (data_valid && !is_dout_block) begin
		mul_outvalid <= 1'b1;
	end else if (!is_dout_block) begin
		mul_outvalid <= 1'b0;
	end
end

// add
genvar ai,vi;
reg signed [2 * DWIDTH + AWIDTH - 1:0] add_result [2 ** AWIDTH - 2:0];
reg [AWIDTH - 1:0]add_outvalid;
generate
	for (ai = 0; ai <= 2 ** AWIDTH - 2; ai = ai + 1) begin
		wire [2 * DWIDTH + AWIDTH - 1:0] this_din_a,this_din_b;
		// wire this_valid;
		if(ai * 2 + 1 > (2 ** AWIDTH) - 2 + WINLEN) begin
			assign this_din_a = {2 * DWIDTH + AWIDTH {1'b0}};
		end else if (ai * 2 + 1 > 2 ** AWIDTH - 2) begin
			assign this_din_a = mul_result[(ai * 2 + 1) - (2 ** AWIDTH - 2) - 1];
		end else begin
			assign this_din_a = add_result[ai * 2 + 1];
		end

		if(ai * 2 + 2 > (2 ** AWIDTH) - 2 + WINLEN) begin
			assign this_din_b = {2 * DWIDTH + AWIDTH {1'b0}};
		end else if (ai * 2 + 2 > 2 ** AWIDTH - 2) begin
			assign this_din_b = mul_result[(ai * 2 + 2) - (2 ** AWIDTH - 2) - 1];
		end else begin
			assign this_din_b = add_result[ai * 2 + 2];
		end

		always @ (posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				add_result[ai] <= {(2*DWIDTH+AWIDTH){1'b0}};
			end else if (!is_dout_block) begin
				add_result[ai] <= this_din_a + this_din_b;
			end
		end
	end
endgenerate
generate
	for (vi = 0; vi < AWIDTH; vi = vi + 1) begin:proc_vi
		wire last_valid;
		if (vi == 0) begin
			assign last_valid = mul_outvalid;
		end else begin
			assign last_valid = add_outvalid[vi - 1];
		end
		always @ (posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				add_outvalid[vi] <= 1'b0;
			end else if (last_valid && !is_dout_block) begin
				add_outvalid[vi] <= 1'b1;
			end else if (!last_valid && !is_dout_block) begin
				add_outvalid[vi] <= 1'b0;
			end
		end
	end
endgenerate

// dout
assign fir_dout_valid = add_outvalid[AWIDTH - 1];
assign fir_dout_data = add_result[0][OSTART+:OWIDTH];

// cfg
wire is_finish = !is_din && !block_sign && !data_valid && !mul_outvalid && (add_outvalid == {AWIDTH{1'b0}}) && !is_dout;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cfg_busy <= 1'b0;
	end else if (is_din) begin
		cfg_busy <= 1'b1;
	end else if (is_finish) begin
		cfg_busy <= 1'b0;
	end
end

endmodule