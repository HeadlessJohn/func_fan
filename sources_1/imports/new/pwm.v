`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////




module pwm_controller #(
    parameter SYS_FREQ = 125, //125MHz
    parameter N = 12 // 2^7 = 128단계
    )(
    input clk, reset_p,
    input [N-1:0] duty, //N비트의 duty비트
    input [13:0] pwm_freq,
    output reg pwm    );

    localparam REAL_SYS_FREQ = SYS_FREQ * 1000 * 1000;

    reg [26:0] cnt;
    reg pwm_clk_nbit; // 
    
    //clock에 관계 없는 부분이므로 나눗셈을 사용해도 negative slack이 발생하지 않음
    //처음에 나눗셈을 계산하는동안 긴 pdt 시간 동안 오동작 발생 가능성 있음
    wire [26:0] temp;
    assign temp = (REAL_SYS_FREQ /pwm_freq);

    always @(posedge reset_p, posedge clk) begin
        if (reset_p) begin
            pwm_clk_nbit <= 0;
            cnt <= 0;
        end
        else begin
            // 128단계 제어 -> 2^7로 나누므로 우쉬프트 연산으로 대체 가능
            if (cnt >= temp[26:N] - 1) begin
            // 100단계 제어
            // if (cnt >= REAL_SYS_FREQ /pwm_freq /100 - 1) begin
                cnt <= 0;
                pwm_clk_nbit <= 1'b1;
            end
            else begin
                pwm_clk_nbit <= 1'b0;
            end
            cnt = cnt + 1;

        end
    end

    reg [N-1:0] cnt_duty;
    always @(posedge reset_p, posedge clk) begin
        if (reset_p) begin
            pwm <= 1'b0;
            cnt_duty <= 0;
        end
        else begin
            if (pwm_clk_nbit) begin
                //2^N단계로 제어
                cnt_duty <= cnt_duty + 1;
                if(cnt_duty < duty) pwm <= 1'b1;
                else pwm <= 1'b0;
            end           
        end
    end
endmodule


module pwm_controller_period #(
    parameter SYS_FREQ = 125, //125MHz
    parameter N = 12 // 2^12 = 4096단계
    ) (
    input clk, reset_p,
    input [26:0] duty,
    input [26:0] pwm_period, 
    output reg pwm  );

    localparam REAL_SYS_FREQ = SYS_FREQ * 1000 * 1000;

    reg [26:0] cnt;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            pwm = 0;
            cnt = 0;
        end
        else begin
            if (cnt >= pwm_period -1 ) begin 
                cnt = 0;
            end
            else cnt = cnt + 1;

            if (cnt > duty) pwm = 0;
            else pwm = 1;
        end
    end
endmodule