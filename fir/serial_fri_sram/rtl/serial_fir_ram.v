
// pro-gen:start here,coding before this line
module serial_fir_ram #(
	parameter DWIDTH = 8,
	parameter AWIDTH = 6,
	parameter WINLEN = 64,
	parameter OWIDTH = 22,
	parameter OSTART = 0
) (
	input clk,
	input rst_n,
	input cfg_valid,
	input [AWIDTH - 1 : 0] cfg_addr,
	input [DWIDTH - 1 : 0] cfg_data,
	input fir_din_valid,
	output reg fir_din_busy,
	input [DWIDTH - 1 : 0] fir_din_data,
	output reg fir_dout_valid,
	input fir_dout_busy,
	output [OWIDTH - 1 : 0] fir_dout_data
);


//instance u_input_ram module single_port_sram
parameter u_input_ram_DWIDTH = DWIDTH;
parameter u_input_ram_AWIDTH = AWIDTH;
wire u_input_ram_clk;
wire u_input_ram_rst_n;
wire [u_input_ram_AWIDTH - 1:0] u_input_ram_address;
wire u_input_ram_write_req;
wire [u_input_ram_DWIDTH - 1:0] u_input_ram_write_data;
wire [u_input_ram_DWIDTH - 1:0] u_input_ram_read_data;
single_port_sram #(
	.DWIDTH(u_input_ram_DWIDTH),
	.AWIDTH(u_input_ram_AWIDTH)
) u_input_ram (
	.clk(u_input_ram_clk),
	.rst_n(u_input_ram_rst_n),
	.address(u_input_ram_address),
	.write_req(u_input_ram_write_req),
	.write_data(u_input_ram_write_data),
	.read_data(u_input_ram_read_data)
);

//instance u_weight_ram module single_port_sram
parameter u_weight_ram_DWIDTH = DWIDTH;
parameter u_weight_ram_AWIDTH = AWIDTH;
wire u_weight_ram_clk;
wire u_weight_ram_rst_n;
wire [u_weight_ram_AWIDTH - 1:0] u_weight_ram_address;
wire u_weight_ram_write_req;
wire [u_weight_ram_DWIDTH - 1:0] u_weight_ram_write_data;
wire [u_weight_ram_DWIDTH - 1:0] u_weight_ram_read_data;
single_port_sram #(
	.DWIDTH(u_weight_ram_DWIDTH),
	.AWIDTH(u_weight_ram_AWIDTH)
) u_weight_ram (
	.clk(u_weight_ram_clk),
	.rst_n(u_weight_ram_rst_n),
	.address(u_weight_ram_address),
	.write_req(u_weight_ram_write_req),
	.write_data(u_weight_ram_write_data),
	.read_data(u_weight_ram_read_data)
);
// link
assign u_weight_ram_rst_n = rst_n;
assign u_input_ram_rst_n = rst_n;
assign u_input_ram_clk = clk;
assign u_weight_ram_clk = clk;
// this on link:
	// serial_fir_ram.fir_din_data
	//serial_fir_ram.cfg_addr
	//serial_fir_ram.cfg_data
	//u_input_ram.write_req
	//serial_fir_ram.fir_din_busy
	//serial_fir_ram.fir_dout_busy
	//u_weight_ram.address
	//serial_fir_ram.fir_dout_valid
	//u_weight_ram.write_data
	//u_weight_ram.read_data
	//u_input_ram.write_data
	//u_weight_ram.write_req
	//serial_fir_ram.fir_din_valid
	//serial_fir_ram.cfg_valid
	//serial_fir_ram.fir_dout_data
	//u_input_ram.read_data
	//u_input_ram.address
// pro-gen:stop here,coding after this line

// port 
wire is_din = fir_din_valid && !fir_din_busy;
wire is_dout = fir_dout_valid && !fir_dout_busy;
wire is_cfg = cfg_valid && !fir_din_busy;

// fsm
localparam INIT = 2'b00;
localparam DAIN = 2'b01;
localparam COMT = 2'b11;
localparam DOUT = 2'b10;
reg [1:0] mode,next_mode;
wire is_init_dain = is_din;
wire is_comt_dout;
wire is_dout_init = is_dout;

// mem
reg [AWIDTH - 1:0] compute_count;
reg [AWIDTH - 1:0] base_point;
reg [AWIDTH - 1:0] input_point;
reg input_write_req;
reg [DWIDTH - 1:0] write_data;

// compute valid and data
reg signed [2*DWIDTH - 1:0] mul_result;
reg signed [2 * DWIDTH + AWIDTH - 1:0] add_result;
reg signed [DWIDTH - 1:0] mul_din,mul_weight;
reg data_valid,mul_outvalid;

// fsm
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mode <= INIT;
	end else begin
		mode <= next_mode;
	end
end

always @ (*) begin
	case (mode)
		INIT:begin
			if (is_init_dain) begin
				next_mode = DAIN;
			end else begin
				next_mode = INIT;
			end
		end 
		DAIN:next_mode = COMT;
		COMT:begin
			if (is_comt_dout) begin
				next_mode = DOUT;
			end else begin
				next_mode = COMT;
			end
		end
		DOUT:begin
			if (is_dout_init) begin
				next_mode = INIT;
			end else begin
				next_mode = DOUT;
			end
		end
		default:next_mode = INIT;
	endcase
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		compute_count <= {AWIDTH{1'b0}};
	end else if (mode == INIT) begin
		compute_count <= {AWIDTH{1'b0}};
	end else if (next_mode == COMT) begin
		compute_count <= compute_count + 1'b1;
	end
end
assign is_comt_dout = (compute_count == WINLEN);

// addr
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		base_point <= {AWIDTH{1'b0}};
	end else if (is_dout_init) begin
		base_point <= base_point + 1'b1;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		input_point <= {AWIDTH{1'b0}};
	end else if (next_mode == COMT) begin
		input_point <= input_point - 1'b1;
	end else if (mode == INIT) begin
		input_point <= base_point;
	end
end

// control
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_valid <= 1'b0;
	end else if (next_mode == COMT) begin
		data_valid <= 1'b1;
	end else begin
		data_valid <= 1'b0;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mul_outvalid <= 1'b0;
	end else begin
		mul_outvalid <= data_valid;
	end
end

// write
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		write_data <= {DWIDTH{1'b0}};
	end else if (is_din) begin
		write_data <= fir_din_data;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		input_write_req <= 1'b0;
	end else begin
		input_write_req <= is_din;
	end
end

// memory
assign u_input_ram_address = input_point;
assign u_input_ram_write_req = input_write_req;
assign u_input_ram_write_data = write_data;

assign u_weight_ram_address = (is_cfg)?cfg_addr:compute_count;
assign u_weight_ram_write_req = is_cfg;
assign u_weight_ram_write_data = cfg_data;

// read data
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mul_din <= {DWIDTH{1'b0}};
		mul_weight <= {DWIDTH{1'b0}};
	end else begin
		if (input_write_req) begin
			mul_din <= write_data;
		end else begin
			mul_din <= u_input_ram_read_data;
		end
		mul_weight <= u_weight_ram_read_data;
	end
end
// mul
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mul_result <= {2*DWIDTH{1'b0}};
	end else if (data_valid) begin
		mul_result <= mul_din * mul_weight;
	end
end
// add
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		add_result <= {2*DWIDTH+AWIDTH{1'b0}};
	end else if (is_din) begin
		add_result <= {2*DWIDTH+AWIDTH{1'b0}};
	end else if (mul_outvalid) begin
		add_result <= add_result + mul_result;
	end
end

// port
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		fir_dout_valid <= 1'b0;
	end else if (mul_outvalid && !data_valid) begin
		fir_dout_valid <= 1'b1;
	end else if (is_dout) begin
		fir_dout_valid <= 1'b0;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		fir_din_busy <= 1'b0;
	end else if (is_din) begin
		fir_din_busy <= 1'b1;
	end else if (is_dout) begin
		fir_din_busy <= 1'b0;
	end
end
assign fir_dout_data = {add_result[2 * DWIDTH + AWIDTH - 1],add_result[OSTART+:OWIDTH-1]};

endmodule
