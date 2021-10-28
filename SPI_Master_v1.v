`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Branden Applewhite
// 
// Create Date:
// Design Name: 
// Module Name:   
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
module SPI_Master_v1(
    input wire i_wr,
    input wire i_rd,
    input wire i_cs,
    input wire[1:0] i_address, 
    input wire[7:0] i_data,
    input wire i_clk,
    output reg[7:0] o_data,
    inout io_mosi,
    input i_miso,
    inout sclk
    );
    
    // output buffers
    reg r_sclk_buf = 0;
    reg r_mosi_buf = 0;
    // busy = 0 if no data to receive or send
    reg r_busy = 0;
    // shift register
    reg[7:0] r_in_buf = 0;
    reg[7:0] r_out_buf = 0;

    reg[7:0] r_clk_cnt = 0;
    // division of clk 
    reg[7:0] r_clk_div = 0;
    
    reg[4:0] r_cnt = 0;

    assign sclk = r_sclk_buf;
    assign io_mosi = r_mosi_buf;

    // on positive edge of sclk, read miso data into buffer (Mode 0)
    always @(posedge r_sclk_buf) begin
        r_out_buf[0] <= i_miso;
        r_out_buf <= r_out_buf << 1;
    end 

    always @(i_cs or i_wr or i_rd or i_address or out_buf or r_busy or r_clk_div) begin
        o_data = i_data;
        if (i_cs && i_rd) begin
            case(i_address)
                2'b00 : o_data = r_out_buf;
                2'b01 : o_data = {7'b0 , r_busy};
                2'b10 : o_data = r_clk_div;
                default : o_data = o_data;
            endcase
        end
    end
    
    // data written to mosi on negative edge
    always @(posedge i_clk) begin
        if (!r_busy) begin 
            if(i_cs && i_wr) begin
                case(i_address)
                    2'b00 : begin
                        r_in_buf <= i_data;
                        r_busy <= 1;
                        r_cnt <= 0;
                    end
                    2'b10 : begin
                        r_in_buf <= r_clk_div;
                    end
                    default : r_in_buf <= r_in_buf; 
                endcase
            end
            else if(i_cs && i_rd) begin
                r_busy <= 1;
                r_cnt <= 0;
            end
        end
        else begin // send data once buffer is filled
            r_clk_cnt <= r_clk_cnt + 1;
            if (r_clk_cnt >= r_clk_div) begin
                r_clk_cnt <= 0;

                if (r_cnt % 2 == 0) begin 
                    r_mosi_buf <= r_in_buf[7];
                    r_in_buf <= r_in_buf << 1;
                end 
                else begin
                    r_mosi_buf <= r_mosi_buf;
                end

                if (r_cnt > 0 && r_cnt < 17) begin
                    r_sclk_buf <= ~r_sclk_buf;
                end

                // 8-bits sent over
                if (r_cnt >= 17) begin 
                    r_cnt <= 0;
                    r_busy <= 0;
                end
                else begin
                    r_cnt <= r_cnt;
                    r_busy <= r_busy;
                end

                r_cnt <= r_cnt + 1;
            end
        end
    end


    


endmodule
