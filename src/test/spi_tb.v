`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:18:36 12/11/2021
// Design Name:   spi
// Module Name:   E:/projects/Xilinx/SPI/XilinxISE/vtest/spi_tb.v
// Project Name:  spi_module
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: spi
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

`define DATA_LEN		8
`define CLK_FREQ		50_000_000
`define SPI_FREQ		1_000_000

module spi_tb;

	// Inputs
	reg rst;
	reg clk;
	wire miso;
	reg [`DATA_LEN - 1:0] transmit_data;
	reg transfer;

	// Outputs
	wire mosi;
	wire sclk;
	wire ready;
	wire [`DATA_LEN - 1:0] received_data;

	localparam CLK_PERIOD = 1_000_000_000 / (`CLK_FREQ * 2);
	localparam SPI_CLK_HALF_PERIOD = 1_000_000_000 / (`SPI_FREQ * 4);

	integer i;

	// Instantiate the Unit Under Test (UUT)
	spi #(	.DL(`DATA_LEN),
        	.CKL_FREQ(`CLK_FREQ),      	// 50 MHz clk pin clock frequency
        	.SPI_FREQ(`SPI_FREQ),       // 500 KHz sclk out clock frequence
        	.CPOL(0),                  	// sclk polarity
        	.CPHA(0))
		uut(
		.rst(rst), 
		.clk(clk), 
		.miso(miso), 
		.mosi(mosi), 
		.sclk(sclk), 
		.transmit_data(transmit_data), 
		.transfer(transfer), 
		.ready(ready), 
		.received_data(received_data)
	);

	initial begin
		// Initialize Inputs
		rst = 0;
		clk = 0;
		transmit_data = 0;
		transfer = 0;

		// Wait 100 ns for global reset to finish
		#10;
		rst = 1;
		#50;
		transmit_data = 8'hAA;
		transfer = 1;
		#(CLK_PERIOD * 2);
		transfer = 0;
		wait(ready == 1);
		if(received_data == 8'hAA) begin
			$display("Transfer success");
		end
		else begin
			$display("Transfer errror");
		end
		#(CLK_PERIOD * 2);
		$finish;


	end

always begin
	clk = ~clk;
	#CLK_PERIOD;
end

assign miso = mosi;

endmodule

