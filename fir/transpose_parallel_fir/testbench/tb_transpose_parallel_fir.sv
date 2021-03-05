// pro-gen:start here,coding before this line
interface port_dut #(
	parameter DWIDTH = 8,
	parameter AWIDTH = 6,
	parameter WINLEN = 64,
	parameter OWIDTH = 22,
	parameter OSTART = 0
)(
	input clk,
	input rst_n
);
	logic cfg_valid;
	logic cfg_busy;
	logic [AWIDTH - 1:0] cfg_addr;
	logic [DWIDTH - 1:0] cfg_data;
	logic fir_din_valid;
	logic fir_din_busy;
	logic [DWIDTH - 1:0] fir_din_data;
	logic fir_dout_valid;
	logic fir_dout_busy;
	logic [OWIDTH - 1:0] fir_dout_data;

	// manage timing in clocking block like this
	clocking cb @(posedge clk);
		output cfg_valid;
		input cfg_busy;
		output cfg_addr;
		output cfg_data;
		output fir_din_valid;
		input fir_din_busy;
		output fir_din_data;
		input fir_dout_valid;
		output fir_dout_busy;
		input fir_dout_data;
	endclocking
endinterface // port_dut

module tb_transpose_parallel_fir ();

//instance dut module transpose_parallel_fir
parameter dut_DWIDTH = 8; // cannot find,use default
parameter dut_AWIDTH = 6; // cannot find,use default
parameter dut_WINLEN = 64; // cannot find,use default
parameter dut_OWIDTH = 22; // cannot find,use default
parameter dut_OSTART = 0; // cannot find,use default
logic dut_clk;
logic dut_rst_n;
logic dut_cfg_valid;
logic dut_cfg_busy;
logic [dut_AWIDTH - 1:0] dut_cfg_addr;
logic [dut_DWIDTH - 1:0] dut_cfg_data;
logic dut_fir_din_valid;
logic dut_fir_din_busy;
logic [dut_DWIDTH - 1:0] dut_fir_din_data;
logic dut_fir_dout_valid;
logic dut_fir_dout_busy;
logic [dut_OWIDTH - 1:0] dut_fir_dout_data;
transpose_parallel_fir #(
	.DWIDTH(dut_DWIDTH),
	.AWIDTH(dut_AWIDTH),
	.WINLEN(dut_WINLEN),
	.OWIDTH(dut_OWIDTH),
	.OSTART(dut_OSTART)
) dut (
	.clk(dut_clk),
	.rst_n(dut_rst_n),
	.cfg_valid(dut_cfg_valid),
	.cfg_busy(dut_cfg_busy),
	.cfg_addr(dut_cfg_addr),
	.cfg_data(dut_cfg_data),
	.fir_din_valid(dut_fir_din_valid),
	.fir_din_busy(dut_fir_din_busy),
	.fir_din_data(dut_fir_din_data),
	.fir_dout_valid(dut_fir_dout_valid),
	.fir_dout_busy(dut_fir_dout_busy),
	.fir_dout_data(dut_fir_dout_data)
);

logic auto_tb_clock,auto_tb_reset_n;
initial begin
    auto_tb_clock = 'b0;
    forever begin
        #5 auto_tb_clock = ~auto_tb_clock;
    end
end
initial begin
    auto_tb_reset_n = 'b0;
    #2 auto_tb_reset_n = 1'b1;
end


string dump_file;
initial begin
    `ifdef DUMP
        if($value$plusargs("FSDB=%s",dump_file))
            $display("dump_file = %s",dump_file);
        $fsdbDumpfile(dump_file);
        $fsdbDumpvars(0, tb_transpose_parallel_fir);
        $fsdbDumpMDA(0, tb_transpose_parallel_fir);
    `endif
end


// assign your clock and reset here
assign dut_clk = auto_tb_clock;
assign dut_rst_n = auto_tb_reset_n;

port_dut#(
	.DWIDTH(dut_DWIDTH),
	.AWIDTH(dut_AWIDTH),
	.WINLEN(dut_WINLEN),
	.OWIDTH(dut_OWIDTH),
	.OSTART(dut_OSTART)
) link_dut(dut_clk,dut_rst_n);
assign dut_cfg_valid = link_dut.cfg_valid;
assign link_dut.cfg_busy = dut_cfg_busy;
assign dut_cfg_addr = link_dut.cfg_addr;
assign dut_cfg_data = link_dut.cfg_data;
assign dut_fir_din_valid = link_dut.fir_din_valid;
assign link_dut.fir_din_busy = dut_fir_din_busy;
assign dut_fir_din_data = link_dut.fir_din_data;
assign link_dut.fir_dout_valid = dut_fir_dout_valid;
assign dut_fir_dout_busy = link_dut.fir_dout_busy;
assign link_dut.fir_dout_data = dut_fir_dout_data;

testbench_dut#(
	.DWIDTH(dut_DWIDTH),
	.AWIDTH(dut_AWIDTH),
	.WINLEN(dut_WINLEN),
	.OWIDTH(dut_OWIDTH),
	.OSTART(dut_OSTART)
) tb_dut (link_dut);
endmodule

program testbench_dut #(
	parameter DWIDTH = 8,
	parameter AWIDTH = 6,
	parameter WINLEN = 64,
	parameter OWIDTH = 22,
	parameter OSTART = 0
) ( port_dut port );
// pro-gen:stop here,coding after this line


endprogram