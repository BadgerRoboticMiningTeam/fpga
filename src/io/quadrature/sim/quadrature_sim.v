`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2016 06:29:52 PM
// Design Name: 
// Module Name: quadrature_sim
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


module quadrature_sim();
    reg read_en, clk, rst;
    wire data_valid;
    wire [63:0] data_out;
	
	reg [25:0] quad_a_setup;
	reg [25:0] quad_b_setup;

    quadrature_reader reader(
        .encode_a(quad_a_setup[25]),
        .encode_b(quad_b_setup[25]),
        .read_en(read_en),
        .data_valid(data_valid),
        .data_out(data_out),
        .clk(clk),
        .rst(rst));
    
    initial begin
        read_en <= 0;
        clk <= 0;
        rst <= 1;
		quad_a_setup <= 26'b10011001100011001100100110;
		quad_b_setup <= 26'b11001100110110011001110011;
        #10;
        rst <= 0;
    end
    
    always #150 begin
        read_en <= 1;
    end
	always @(negedge(data_valid)) begin
		read_en <= 0;
	end
    
    always #1 clk <= !clk;
	
	always #15 begin
		quad_a_setup <= quad_a_setup << 1;
		quad_b_setup <= quad_b_setup << 1;
	end
endmodule