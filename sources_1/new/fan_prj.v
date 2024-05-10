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
    input fan_en,
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

    // 버튼 입력부 컨트롤러
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

    // btn 입력에 따른 state 변경 로직
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= S_IDLE;
        end
        else begin
            if (fan_en) begin // fan_en이 활성화 되었을 때만 동작
                if (btn_p) begin
                    next_state <= {state[6:0], state[7]}; // state를 1비트씩 shift하여 다음 state로 이동
                end 
            end
            else begin // fan_en이 0인 경우 IDLE 상태로 이동- fan 멈춤
                next_state <= S_IDLE;
            end
        end
    end

    // state 별 듀티 제어
    reg [N-1:0] fan_duty;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            fan_duty <= 0;
        end
        else begin
            case (state)
                S_IDLE : begin
                    fan_duty <= 0;
                end

                S_1 : begin
                    fan_duty <= 1023;
                end

                S_2 : begin
                    fan_duty <= 1535;
                end

                S_3 : begin
                    fan_duty <= 2047;
                end

                S_4 : begin
                    fan_duty <= 2559;
                end

                S_5 : begin
                    fan_duty <= 3071;
                end

                S_6 : begin
                    fan_duty <= 3583;
                end

                S_7 : begin
                    fan_duty <= 4095;
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
