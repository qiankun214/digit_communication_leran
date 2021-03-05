`include "../lib_fir.sv"
// pro-gen:start here,coding before this line
module tb_serial_fir_ram ();

//instance dut module serial_fir_ram
parameter dut_DWIDTH = 8; // cannot find,use default
parameter dut_AWIDTH = 6; // cannot find,use default
parameter dut_WINLEN = 63; // cannot find,use default
parameter dut_OWIDTH = 22; // cannot find,use default
parameter dut_OSTART = 0; // cannot find,use default
logic dut_clk;
logic dut_rst_n;
logic dut_cfg_valid;
logic [dut_AWIDTH - 1:0] dut_cfg_addr;
logic [dut_DWIDTH - 1:0] dut_cfg_data;
logic dut_fir_din_valid;
logic dut_fir_din_busy;
logic [dut_DWIDTH - 1:0] dut_fir_din_data;
logic dut_fir_dout_valid;
logic dut_fir_dout_busy;
logic [dut_OWIDTH - 1:0] dut_fir_dout_data;
serial_fir_ram #(
	.DWIDTH(dut_DWIDTH),
	.AWIDTH(dut_AWIDTH),
	.WINLEN(dut_WINLEN),
	.OWIDTH(dut_OWIDTH),
	.OSTART(dut_OSTART)
) dut (
	.clk(dut_clk),
	.rst_n(dut_rst_n),
	.cfg_valid(dut_cfg_valid),
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
        $fsdbDumpvars(0, tb_serial_fir_ram);
        $fsdbDumpMDA(0, tb_serial_fir_ram);
    `endif
end


// assign your clock and reset here
assign dut_clk = auto_tb_clock;
assign dut_rst_n = auto_tb_reset_n;

// pro-gen:stop here,coding after this line
fir_port #(dut_AWIDTH,dut_DWIDTH,dut_OWIDTH) port (dut_clk,dut_rst_n);
assign dut_cfg_valid = port.cfg_valid;
assign dut_cfg_addr = port.cfg_addr;
assign dut_cfg_data = port.cfg_data;

assign dut_fir_din_valid = port.din_valid;
assign port.din_busy = dut_fir_din_busy;
assign dut_fir_din_data = port.din_data;

assign port.dout_valid = dut_fir_dout_valid;
assign dut_fir_dout_busy = port.dout_busy;
assign port.dout_data = dut_fir_dout_data;

testbench #(dut_AWIDTH,dut_DWIDTH,dut_OWIDTH,dut_WINLEN) tb (port);

endmodule