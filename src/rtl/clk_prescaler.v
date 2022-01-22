`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:09:23 12/04/2021 
// Design Name: 
// Module Name:    clk_prescaler 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clk_prescaler #(parameter CLK_FREQ = 50_000_000,
                    parameter OUT_CLK = 500_000)
    (
    input rst,
    input clk,
    input en,
    output pres_clk
    );

localparam MAX_COUNTER_VALUE = (CLK_FREQ / OUT_CLK) * 2;

reg [9:0] counter = 0;      //TODO configure size of the reg
reg out_clk = 1'b0;

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        counter <= 0;
        out_clk <= 1'b0;
    end
    else if(en == 1'b1) begin
        if(counter >= MAX_COUNTER_VALUE) begin
            counter <= 0;
            out_clk <= ~out_clk;
        end
        else begin
            counter <= counter + 1'b1;
            out_clk <= out_clk;
        end
    end
    else begin
        counter <= 0;
        out_clk <= 1'b0;
    end
end
assign pres_clk = out_clk;

endmodule
