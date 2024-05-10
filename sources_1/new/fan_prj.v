`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2024 11:37:55 AM
// Design Name: 
// Module Name: fan_prj
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


module fan_controller #(SYS_FREQ = 125, N = 12) (
    input clk, reset_p,
    input btn,
    output [7:0] led_bar,
    output pwm   );

    //state 정의
    localparam S_IDLE = 8'b0000_0001;
    localparam S_1    = 8'b0000_0010;
    localparam S_2    = 8'b0000_0100;
    localparam S_3    = 8'b0000_1000;
    localparam S_4    = 8'b0001_0000;
    localparam S_5    = 8'b0010_0000;
    localparam S_6    = 8'b0100_0000;
    localparam S_7    = 8'b1000_0000;

    // 버튼 입력부
    wire btn_p;
    button_cntr btn0(clk, reset_p, btn, btn_p);

    // FSM 
    reg [7:0] state, next_state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    // state 별 듀티 제어
    reg [N-1:0] fan_duty;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            fan_duty <= 0;
            next_state <= S_IDLE;
        end
        else begin
            case (state)
                S_IDLE : begin
                    if (btn_p) begin
                        next_state <= S_1;
                    end
                    else begin
                        fan_duty <= 0;
                    end
                end

                S_1 : begin
                    if (btn_p) begin
                        next_state <= S_2;
                    end
                    else begin
                        fan_duty <= 1023;
                    end
                end

                S_2 : begin
                    if (btn_p) begin
                        next_state <= S_3;
                    end
                    else begin
                        fan_duty <= 1535;
                    end
                end

                S_3 : begin
                    if (btn_p) begin
                        next_state <= S_4;
                    end
                    else begin
                        fan_duty <= 2047;
                    end
                end

                S_4 : begin
                    if (btn_p) begin
                        next_state <= S_5;
                    end
                    else begin
                        fan_duty <= 2559;
                    end
                end

                S_5 : begin
                    if (btn_p) begin
                        next_state <= S_6;
                    end
                    else begin
                        fan_duty <= 3071;
                    end
                end

                S_6 : begin
                    if (btn_p) begin
                        next_state <= S_7;
                    end
                    else begin
                        fan_duty <= 3583;
                    end
                end

                S_7 : begin
                    if (btn_p) begin
                        next_state <= S_IDLE;
                    end
                    else begin
                        fan_duty <= 4095;
                    end
                end

            endcase
        end
    end

    //PWM 출력 모듈
    //200Hz 0~4095 듀티
    pwm_controller #(SYS_FREQ, N) (.clk(clk),
                                   .reset_p(reset_p),
                                   .duty(fan_duty), //0~4095
                                   .pwm_freq(200),
                                   .pwm(pwm)
                                   );
    //디버깅용 LED연결
    assign led_bar = state;
endmodule
