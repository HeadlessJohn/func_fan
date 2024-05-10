`timescale 1ns / 1ps

// T_FF 을 이용한 4비트 업카운터
module up_counter_async(
    input clk, reset_p,
    output [3:0] count
    );

    //0~F 까지 출력
    T_flip_flop_n T0(.clk(clk),      .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule

// T_FF 을 이용한 4비트 다운카운터
module down_counter_async(
    input clk, reset_p,
    output [3:0] count
    );
    //0~F 까지 출력
    T_flip_flop_p T0(.clk(clk),      .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule

module up_counter_p (
    input clk, reset_p,
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) count = 4'b0000;
        else count = count+1;
    end
endmodule

module down_counter_nbit_p #(parameter N=4'b1000)(
    input clk, reset_p, enable,
    output reg [N-1:0] count
);
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) count = 0;
        else begin
            if (enable) count = count-1;
            else count = count;
        end
    end
endmodule


module bcd_up_counter_p (
    input clk, reset_p,
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) count = 4'b0000;
        else begin
            count = count + 1;
            if (count==10) count=0;
        end
    end
endmodule


module bcd_up_down_counter_p (
    input clk, reset_p, sel, // 0 up, 1 down
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p) begin // clk, reset의 상승엣지에서 작동
        if(reset_p) count = 4'b0000; // 초기화 입력
        else begin
            count = sel ? count-1 : count + 1; // sel 0 일때 up,  1일때 down
            if (count==10) count=0; // 10이되었을때 0으로 초기화
            else if (count==15) count=9; // 0에서 -1하여 15가 되었을때 9로
            else count = count;
        end
    end
endmodule

module bcd_up_down_counter_p2 (
    input clk, reset_p, sel, // 0 up, 1 down
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p) begin // clk, reset의 상승엣지에서 작동
        if(reset_p) count = 4'b0000; // 초기화 입력
        else begin
            count = sel ? count - 1 : count + 1;
            case ( {sel,count} )
                5'b0_1010 : count = 0;  //up, 10->0
                5'b1_1111 : count = 9;  //down, 15->9
                default : count = count;
            endcase
        end
    end
endmodule


module up_down_counter_nbit_p #(parameter N=4'b1000)(
    input clk, reset_p, enable, sel, //0이면 상향 1이면 하향
    output reg [N-1:0] count
);
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) count = 0;
        else begin
            if (enable) count = sel? count-1 : count+1;
            else count = count;
        end
    end
endmodule