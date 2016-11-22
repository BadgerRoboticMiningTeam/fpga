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
	wire scl, sda;
	
	reg supply;
	
	reg [3:0] bytes_left;
	
	reg master_init;
	reg [6:0] master_slave_addr;
	reg master_rd_wr;
	reg [7:0] master_wr_data;
	wire master_busy;
	wire [7:0] master_rd_data;
	wire master_ack_err;
	
	reg [7:0] slave_wr_data;
	reg slave_wr_en;
	wire [7:0] slave_rd_data;
	wire slave_rd_valid, slave_wr_acked;
	wire slave_selected, slave_io_busy;
	
	reg clk, rst;
	
	assign (pull1, highz0) scl = supply;
	assign (pull1, highz0) sda = supply;
	
	i2c_master master(
		.clk(clk),
		.reset_n(!rst),
		.ena(master_init),
		.addr(master_slave_addr),
		.rw(master_rd_wr),
		.data_wr(master_wr_data),
		.busy(master_busy),
		.data_rd(master_rd_data),
		.ack_error(master_ack_err),
		.sda(sda),
		.scl(scl)
	);
	
	i2c_slave slave(
		.scl(scl),
		.sda(sda),
		
		.wr_data(slave_wr_data),
		.wr_acked(slave_wr_acked),
		.rd_data(slave_rd_data),
		.rd_valid(slave_rd_valid),
		
		.slave_selected(slave_selected),
		.io_busy(slave_io_busy),
		
		.clk(clk),
		.rst(rst)
	);
	
	initial begin
		supply <= 1;
		
		master_init <= 0;
		master_slave_addr <= 7'b0101010;
		master_rd_wr <= 1;
		master_wr_data <= 8'hBE;
		
		bytes_left <= 4;
		
		slave_wr_data <= 8'd0;
		slave_wr_en <= 0;
		
		clk <= 0;
		rst <= 1;
		
		#20;
		
		rst <= 0;
	end
	
	always #10 clk <= !clk;
	
	always @(negedge(master_busy)) begin
		master_wr_data <= master_wr_data + 1;
		slave_wr_data <= slave_wr_data + 1;
		master_rd_wr <= ~master_rd_wr;
		master_init <= 1;
	end
	
	always @(posedge(slave_wr_acked)) begin
		if (bytes_left == 0) begin
			bytes_left <= 4;
		end
		else begin
			bytes_left <= bytes_left - 1;
			master_init <= 1;
		end
	end
	
	always @(posedge(master_busy)) begin
		master_init <= 0;
	end
endmodule
