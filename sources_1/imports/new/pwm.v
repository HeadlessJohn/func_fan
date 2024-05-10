`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////



module tb_pwm_test();

    reg clk;
    reg reset_p;
    wire pwm;

    //50hz 7.0%duty
    pwm_cntr pwm0(clk, reset_p, pwm, 1000, 100);


    initial begin
        clk = 0;
        reset_p = 1;
        forever #4 clk = ~clk;
    end

    initial begin
        #10 reset_p = 0;
    end
endmodule 

module pwm_test #(
    parameter SYS_FREQ = 125 //125MHz
    )(
    input clk, reset_p,
    output pwm   );

    wire clk_usec, clk_msec, clk_sec;
    clock_usec clk_us0(clk, reset_p, clk_usec);
    clock_div_1000 clk_div0(clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 clk_div1(clk, reset_p, clk_msec, clk_sec);

    wire pwn_0, pwm_1, pwm_2, pwm_3, pwm_4, pwm_5;
    pwm_cntr pwm0(clk, reset_p, pwm_0, 50, 50);
    pwm_cntr pwm1(clk, reset_p, pwm_1, 50, 60);
    pwm_cntr pwm2(clk, reset_p, pwm_2, 50, 70);
    pwm_cntr pwm3(clk, reset_p, pwm_3, 50, 80);
    pwm_cntr pwm4(clk, reset_p, pwm_4, 50, 90);
    pwm_cntr pwm5(clk, reset_p, pwm_5, 50, 100);

    reg [2:0] cnt = 0;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt = 0;
        end
        else begin
            if (clk_sec) begin
                cnt = cnt + 1;
                if (cnt >= 6) cnt = 0;
            end
        end
    end

    assign pwm = cnt == 0 ? pwm_0 :
                 cnt == 1 ? pwm_1 :
                 cnt == 2 ? pwm_2 :
                 cnt == 3 ? pwm_3 :
                 cnt == 4 ? pwm_4 : pwm_5;
endmodule


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