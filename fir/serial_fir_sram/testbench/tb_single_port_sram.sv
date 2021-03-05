// pro-gen:start here,coding before this line
module tb_single_port_sram ();

//instance dut module single_port_sram
parameter dut_DWIDTH = 8; // cannot find,use default
parameter dut_AWIDTH = 6; // cannot find,use default
logic dut_clk;
logic dut_rst_n;
logic [dut_AWIDTH - 1:0] dut_address;
logic dut_write_req;
logic [dut_DWIDTH - 1:0] dut_write_data;
logic [dut_DWIDTH - 1:0] dut_read_data;
single_port_sram #(
	.DWIDTH(dut_DWIDTH),
	.AWIDTH(dut_AWIDTH)
) dut (
	.clk(dut_clk),
	.rst_n(dut_rst_n),
	.address(dut_address),
	.write_req(dut_write_req),
	.write_data(dut_write_data),
	.read_data(dut_read_data)
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
        $fsdbDumpvars(0, tb_single_port_sram);
        $fsdbDumpMDA(0, tb_single_port_sram);
    `endif
end


// assign your clock and reset here
assign dut_clk = auto_tb_clock;
assign dut_rst_n = auto_tb_reset_n;

// pro-gen:stop here,coding after this line
endmodule