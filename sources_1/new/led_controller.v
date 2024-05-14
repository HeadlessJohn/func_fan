`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/14/2024 06:18:24 PM
// Design Name: 
// Module Name: led_controller
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



module led_controller(
    input clk, reset_p,
    input btn,
    input led_clr,
    output led);
    
    parameter IDLE      = 4'b0001;      // OFF
    parameter LED_1STEP = 4'b0010;      // 1단계
    parameter LED_2STEP = 4'b0100;      // 2단계
    parameter LED_3STEP = 4'b1000;      // 3단계
    
    reg [6:0] duty;    
    reg [3:0] state;      // led_ringcounter
    always @(posedge clk, posedge reset_p) begin
        if(reset_p)begin
            state = IDLE;
            duty = 0;
        end
        else begin 
            if(btn)begin
                if(state == IDLE)begin
                    state = LED_1STEP;
                    duty = 13;
                end
                else if(state == LED_1STEP)begin
                    state = LED_2STEP;
                    duty = 38;
                end
                else if(state == LED_2STEP)begin
                    state = LED_3STEP;
                    duty = 64;
                end
                else begin
                    state = IDLE;
                    duty = 0;
                end
            end
            else if (led_clr)begin
                state = IDLE;
                duty = 0;
            end
        end
    end
    
    pwm_controller #(125, 9) (.clk(clk),
                              .reset_p(reset_p),
                              .duty(duty),
                              .pwm_freq(100),
                              .pwm(led)
                              );    
endmodule

