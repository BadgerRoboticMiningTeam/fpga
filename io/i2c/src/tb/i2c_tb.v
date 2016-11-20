`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Badger Robotic Mining Team
// Engineer: Zuodian Hu
// 
// Create Date: 11/19/2016 06:09:28 PM
// Design Name: I2C Test Bench
// Module Name: i2c_tb
// Project Name: Lunar Test Bench
// Target Devices: All
// Tool Versions: Vivado WebPack 2016.3
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_tb();
	reg master_scl, master_sda;
	wire slave_scl, slave_sda;
	reg [7:0] slave_wr_data;
	reg slave_wr_en;
	wire [7:0] slave_rd_data;
	wire slave_rd_valid;
	wire slave_selected, slave_io_busy;
	
	reg [7:0] master_data;
	
	reg clk, rst;
	
	i2c_slave slave(
		.scl_in(master_scl),
		.scl_out(slave_scl),
		.sda_in(master_sda),
		.sda_out(slave_sda),
		.wr_data(slave_wr_data),
		.wr_en(slave_wr_en),
		.rd_data(slave_rd_data),
		.rd_valid(slave_rd_valid),
		.slave_selected(slave_selected),
		.io_busy(slave_io_busy),
		.clk(clk),
		.rst(rst)
	);
	
	initial begin
		master_scl <= 1;
		master_sda <= 1;
		slave_wr_data <= 8'd0;
		slave_wr_en <= 0;
		master_data <= 8'hB4;
		clk <= 0;
		rst <= 1;
		#10;
		rst <= 0;
		#10;
		slave_wr_data <= 8'hBE;
		slave_wr_en <= 1;
		#10;
		slave_wr_en <= 0;
		#20;
		master_sda <= 0;
	end
	
	always #10 clk <= !clk;
	
	always #100 begin
		master_scl <= ~master_scl;
	end
	always @(posedge(master_scl) begin
		
	end
endmodule
