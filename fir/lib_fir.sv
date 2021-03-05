`ifndef LIB_FIR
`define LIB_FIR

interface fir_port#(
    parameter AWIDTH = 6,
    parameter DWIDTH = 8,
    parameter OWIDTH = 24
)(
    input clk,
    input rst_n
);
    // config port
    logic cfg_valid;
    logic [AWIDTH - 1:0] cfg_addr;
    logic [DWIDTH - 1:0] cfg_data;

    // din port
    logic din_valid,din_busy;
    logic [DWIDTH - 1:0] din_data;

    // dout port
    logic dout_valid,dout_busy;
    logic [OWIDTH - 1:0] dout_data;

    clocking cfg @(posedge clk);
        output cfg_valid,cfg_addr,cfg_data;
        input din_busy;
    endclocking

    clocking din @(posedge clk);
        output din_valid,din_data;
        input din_busy;
    endclocking

    clocking dout @(posedge clk);
        output dout_busy;
        input dout_valid,dout_data;
    endclocking

endinterface //fir_port

class fir_data#(int DWIDTH,int WINLEN);

    rand logic signed [DWIDTH - 1:0] din_list [];
    rand logic signed [DWIDTH - 1:0] weight_list [WINLEN - 1:0];
    int result_list []; 

    constraint c {
        din_list.size() > WINLEN + 1;
        din_list.size() <= 4 * WINLEN;
    }

    function void post_randomize();
        result_list = new[din_list.size()];
        for (int i = 0; i < din_list.size(); i = i + 1) begin
            result_list[i] = 0;
            for (int j = 0; j < WINLEN; j++) begin
                if (i - j >= 0) begin
                    result_list[i] = result_list[i] + din_list[i - j] * weight_list[j];
                    // $display("DEBUG:%0d * %0d",din_list[i - j],weight_list[j]);
                end
            end
            $display("\n");
        end
    endfunction

endclass //fir_data

class fir_driver#(parameter AWIDTH,parameter DWIDTH,parameter OWIDTH,parameter WINLEN);
    
    virtual fir_port#(AWIDTH,DWIDTH,OWIDTH) p;
    
    function new(virtual fir_port#(AWIDTH,DWIDTH,OWIDTH) tb_p);
        p = tb_p;

        p.cfg.cfg_valid <= 0;
        p.cfg.cfg_addr <= 0;
        p.cfg.cfg_data <= 0;
    
        p.din.din_valid <= 0;
        p.din.din_data <= 0;

        p.dout.dout_busy <= 0;
    endfunction //new()

    task automatic fir_work(const ref fir_data#(DWIDTH,WINLEN) data);
        for (int i = 0; i < data.din_list.size(); i++) begin
            if (i  == data.din_list.size()/2) begin
                repeat(10) @(p.din);
            end
            p.din.din_valid <= 1'b1;
            p.din.din_data <= data.din_list[i];
            do begin
                @(p.din);
            end while(p.din.din_busy);
            p.din.din_valid <= 1'b0;
        end
    endtask //automatic

    task automatic fir_config(const ref fir_data#(DWIDTH,WINLEN) data);
        for (int i = 0; i < WINLEN; i++) begin
            p.cfg.cfg_valid <= 1'b1;
            p.cfg.cfg_addr <= i;
            p.cfg.cfg_data <= data.weight_list[i];
            do begin
                @(p.cfg);
            end while(p.cfg.din_busy);
            p.cfg.cfg_valid <= 1'b0;
        end
    endtask //automatic
    
endclass //fir_driver

program testbench #(
    parameter AWIDTH = 6,
    parameter DWIDTH = 8,
    parameter OWIDTH = 24,
    parameter WINLEN = 31
) (
    fir_port port
);

fir_data#(DWIDTH,WINLEN) data;
fir_driver#(AWIDTH,DWIDTH,OWIDTH,WINLEN) drv;

initial begin
    data = new();
    data.randomize();
    drv = new(port);
end

initial begin
    repeat(10) @(port.cfg);
    drv.fir_config(data);
end

initial begin
    repeat(2 * WINLEN) @(port.din);
    drv.fir_work(data);
end

initial begin
    int index = 0;
    logic signed[OWIDTH - 1:0] dout_data,dout_ref;
    forever begin
        @(port.dout);
        if (port.dout.dout_valid && !port.dout_busy) begin
            dout_data = port.dout.dout_data;
            dout_ref = data.result_list[index];
            if (dout_data == dout_ref) begin
                $display("INFO:compare %0d successful",dout_data);
            end else begin
                $display("ERROR:compare failed,%0d(dout) != %0d(ref)",dout_data,dout_ref);
            end
            index = index + 1;
        end
        port.dout.dout_busy <= $urandom_range(0,1);
    end
end

initial begin
    #999999 $finish;
end

endprogram

`endif