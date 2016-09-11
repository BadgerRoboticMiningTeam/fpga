`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2016 09:39:45 AM
// Design Name: 
// Module Name: async_multi_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module async_multi_sim();
	reg TxD_start;
	reg [3:0] TxD_bytes;
	reg [63:0] TxD_data;
	wire TxD, busy;
	
	reg clk, rst;

	async_multi transmitter(
		.TxD_start(TxD_start),
		.TxD_bytes(TxD_bytes),
		.TxD_data(TxD_data),
		.TxD(TxD),
		.busy(busy),
		.clk(clk),
		.rst(rst)
	);
	
	initial begin
		TxD_start <= 0;
		TxD_bytes <= 4'b1000;
		TxD_data <= 64'hAAFF0055AAFF0055;
		clk <= 0;
		rst <= 1;
		#20;
		rst <= 0;
		#20;
		TxD_start <= 1;
		#10;
		TxD_start <= 0;
	end
	
	always #5 clk <= !clk;
endmodule