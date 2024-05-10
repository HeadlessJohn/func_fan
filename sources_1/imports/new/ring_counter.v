`timescale 1ns / 1ps

module ring_counter (
    input clk, reset_p,
    output reg [3:0] q
    );
    // cnt 0~1~2~3~0~1~2~3.... 100MHz / 2^18 = 381.47Hz
    // 4segment : 381.47Hz / 4 = 95.37Hz (T=10.49ms)
    // each segment need at least 60Hz (T=16.67ms)
    // always문 내부는 clk에 의해 제어되므로 뒤에 플립플롭이 붙음 
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) q = 4'b0001;
        else 
            case (q)
                4'b0001 : q = 4'b0010;
                4'b0010 : q = 4'b0100;
                4'b0100 : q = 4'b1000;
                default : q = 4'b0001;
            endcase
    end
endmodule

module ring_counter_Nbit # (
    parameter N = 4
    )(
    input clk, reset_p,
    output reg [N-1:0] ring_cnt
    );

    clock_div_Nbit #(15) clk_div_16_pedge(clk, reset_p, clk_div_16);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) ring_cnt = 1'b1;
        else if(clk_div_16) ring_cnt = {ring_cnt[N-2:0], ring_cnt[N-1]}; //left ring shift
    end
endmodule