`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:58:03 12/04/2021 
// Design Name: 
// Module Name:    spi 
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
module spi #(parameter DL = 8,
        parameter CKL_FREQ = 50_000_000,      // 50 MHz clk pin clock frequency
        parameter SPI_FREQ = 500_000,         // 500 KHz sclk out clock frequence
        parameter CPOL = 1,                   // sclk polarity
        parameter CPHA = 1)                  // sclk phase configuration
    (
    input rst,
    input clk,
    input miso,
    output mosi,
    output sclk,
    input [DL - 1 : 0] transmit_data,
    input transfer,
    output ready,
    output [DL - 1 : 0] received_data
    );

wire presc_en;
wire spi_clk;

clk_prescaler #(.CLK_FREQ(CKL_FREQ),
                .OUT_CLK(SPI_FREQ))
my_pres(
    .rst(rst),
    .clk(clk),
    .en(presc_en),
    .pres_clk(spi_clk)
);

// state machine states
localparam STATE_READY = 3'b001,
            STATE_TRANSFER = 3'b010,
            STATE_DONE = 3'b100;

//output registers
wire w_sclk;
reg [DL - 1:0] r_received_data = 0;

// internal regs
reg [DL - 1:0] in_data = 0;
reg [DL - 1:0] out_data = 0;
reg [3:0] bit_counter = 4'b0;

reg spi_clk_next = 1'b0;
reg spi_clk_rising_edge = 1'b0;
reg spi_clk_falling_edge = 1'b0;

reg [2:0] state = STATE_READY;
reg [2:0] next_state;

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        state <= STATE_READY;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state = STATE_READY;
    case(state) 
        STATE_READY : begin
            if(transfer == 1'b1) begin
                next_state = STATE_TRANSFER;
            end
            else begin
                next_state = STATE_READY;
            end
        end
        STATE_TRANSFER : begin
            if(CPHA == 0) begin
                if(bit_counter >= DL) begin
                    next_state = STATE_DONE;
                end
                else begin
                    next_state = STATE_TRANSFER;
                end
            end
            else begin
                if(bit_counter >= DL + 1) begin
                    next_state = STATE_DONE;
                end
                else begin
                    next_state = STATE_TRANSFER;
                end
            end
        end
        STATE_DONE : begin
            next_state = STATE_READY;
        end
    endcase
end

always @(posedge clk) begin
    spi_clk_next <= spi_clk;
    //determining rising edge
    if((spi_clk != spi_clk_next) &&
        (spi_clk == 1'b1)) begin
        spi_clk_rising_edge <= 1'b1;
    end
    else begin
        spi_clk_rising_edge <= 1'b0;
    end
    //determining falling edge
    if((spi_clk != spi_clk_next) &&
        (spi_clk == 1'b0)) begin
        spi_clk_falling_edge <= 1'b1;        
    end
    else begin
        spi_clk_falling_edge <= 1'b0;
    end
end

// counting shift bit
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        bit_counter <= 0;
    end
    if(state == STATE_TRANSFER) begin
        if(CPHA == 0) begin
            if(spi_clk_falling_edge) begin
                bit_counter <= bit_counter + 1'b1;
            end
            else begin
                bit_counter <= bit_counter;
            end
        end
        else begin
            if(spi_clk_rising_edge) begin
                bit_counter <= bit_counter + 1'b1;
            end
            else begin
                bit_counter <= bit_counter;
            end
        end
    end
    else begin
        bit_counter <= 0;
    end
end

// shifting input and output data
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        in_data <= 0;
        out_data <= 0;
    end
    else begin
        if(state == STATE_TRANSFER) begin
            if(CPHA == 0) begin
                if(spi_clk_falling_edge) begin
                    in_data <= {in_data[DL - 2:0], 1'b0};
                end
                else begin
                    in_data <= in_data;
                end
                if(spi_clk_rising_edge) begin
                    out_data <= {out_data[DL - 2:0], miso};
                end
                else begin
                    out_data <= out_data;
                end
            end
            else begin
                if(spi_clk_falling_edge) begin
                    out_data <= {out_data[DL - 2:0], miso};
                end
                else begin
                    out_data <= out_data;
                end
                if((spi_clk_rising_edge) && (bit_counter != 0)) begin
                    in_data <= {in_data[DL - 2:0], 1'b0};
                end
                else begin
                    in_data <= in_data;
                end
            end
        end
        else begin
            in_data <= transmit_data;
            out_data <= 0;
        end
    end
end

//set received data to output register
always @(posedge clk) begin
    if(state == STATE_DONE) begin
        r_received_data <= out_data;
    end
end

assign presc_en = (state == STATE_TRANSFER) ? 1'b1 : 1'b0;
assign w_sclk = (state == STATE_TRANSFER) ? spi_clk : 1'b0;
assign mosi = (state == STATE_TRANSFER) ? in_data[DL - 1] : 1'b0;
assign sclk = (CPOL == 0) ? w_sclk : ~w_sclk;
assign ready = (state == STATE_READY) ? 1'b1 : 1'b0;
assign received_data = r_received_data;

endmodule
