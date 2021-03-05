
// pro-gen:start here,coding before this line
module transpose_parallel_fir #(
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

// din control
reg [DWIDTH - 1:0] block_data;
reg block_sign;
wire [DWIDTH - 1:0] this_din;
wire this_din_valid;
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        block_data <= {DWIDTH{1'b0}};
    end else if(is_din && is_dout_block) begin
        block_data <= fir_din_data;
    end
end
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        block_sign <= 1'b0;
    end else if(is_din && is_dout_block) begin
        block_sign <= 1'b1;
    end else if(is_dout) begin
        block_sign <= 1'b0;
    end
end
assign this_din = (block_sign && is_dout)?block_data:fir_din_data;
assign this_din_valid = block_sign || fir_din_data;

// cfg
wire is_cfg = cfg_valid && !cfg_busy;
reg [DWIDTH - 1:0] weight[WINLEN - 1:0];
genvar wi;
generate
    for(wi = 0;wi < WINLEN;wi = wi + 1) begin
        always @ (posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                weight[wi] <= {DWIDTH{1'b0}};
            end else if(is_cfg && cfg_addr == wi) begin
                weight[wi] <= cfg_data;
            end
        end
    end
endgenerate

// mul vector
reg [2 * DWIDTH - 1:0] mul_result [WINLEN - 1:0];
reg mul_outvalid;
genvar mi;
generate 
    for(mi = 0;mi < WINLEN;mi = mi + 1) begin:proc_mi
        always @ (posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                mul_result[mi] <= {2*DWIDTH{1'b0}};
            end else if(this_din_valid && !is_dout_block) begin
                mul_result[mi] <= cfg_data[mi] * this_din;
            end
        end
    end
endgenerate
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_outvalid <= 1'b0;
    end else if(this_din_valid && !is_dout_block) begin
        mul_outvalid <= this_din_valid;
    end else if(!is_dout_block) begin
        mul_outvalid <= 1'b0;
    end
end

// add
reg [WINLEN - 1:1] add_valid;
genvar ai;
generate
    for(ai = 1;ai < WINLEN;ai = ai + 1) begin:proc_ai
        reg [2 * DWIDTH + ai - 1:0] add_result;
        wire [2 * DWIDTH + ai - 2:0] last_din;
        wire last_valid;
        if(ai == 1) begin
            assign last_valid = mul_outvalid;
            assign last_din = mul_result[0];
        end else begin
            assign last_valid = add_valid[ai - 1];
            assign last_din = proc_ai[ai - 1].add_result;
        end
        always @ (posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                add_result[ai] <= {2 * DWIDTH + i{1'b0}};
            end else if(this_din_valid && !is_dout_block) begin
                add_result[ai] <= last_din + mul_result[ai];
            end
        end
        always @ (posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                add_valid[ai] <= 1'b0;
            end else if(this_din_valid && !is_dout_block) begin
                add_valid[ai] <= last_din;
            end else if(!is_dout_block) begin
                add_valid[ai] <= 1'b0;
            end
        end
    end
endgenerate
assign fir_dout_data = proc_ai.add_result[WINLEN - 1];
assign fir_dout_valid = proc_ai.add_result[WINLEN - 1];

always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cfg_busy <= 1'b0;
    end else if(add_valid != 'b0 || mul_outvalid || this_din_valid) begin
        cfg_busy <= 1'b1;
    end else begin
        cfg_busy <= 1'b0;
    end
end
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        fir_din_busy <= 1'b0;
    end else if(is_dout_block) begin
        fir_din_busy <= 1'b1;
    end else if(is_dout) begin
        fir_din_busy <= 1'b0;
    end
end

endmodule
