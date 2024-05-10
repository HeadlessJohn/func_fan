`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/05 14:49:52
// Design Name: 
// Module Name: exam02_sequential_logic
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

// 펄스 전이 검출기
// 클록을 아주 작은시간만 주어 메모리로써 작동할수 있게 해야함
// 상승엣지 or 하강엣지일때 잠시동안만 출력

module D_flip_flop_n(
    input d,
    input clk,
    input reset_p,
    output reg q
);

    always @(negedge clk or posedge reset_p)
        if(reset_p) q=0;
        else q=d;
    
endmodule

module D_flip_flop_p(
    input d,
    input clk,
    input reset_p,
    output reg q
);

    always @(posedge clk or posedge reset_p)
        if(reset_p) q=0; //동시에 들어올경우 reset되고 else는 무시됨 ->reset이 우선
        else q=d;
    
endmodule


module T_flip_flop_n (
    input t,
    input clk,
    input reset_p,
    output reg q
);
    always @(negedge clk or posedge reset_p ) begin
        if (reset_p) q=0;
        else q = t? ~q : q; 
    end

endmodule


module T_flip_flop_p (
    input clk,
    input reset_p,
    input t,
    output reg q
);
    always @(posedge clk or posedge reset_p ) begin
        if (reset_p) q=0;
        else q = t? ~q : q; 
    end
endmodule

// 레벨트리거 - Latch
// 엣지트리거 - FF
// slack : 타이밍 시간 여유. 음수 나오면 잘못설계된것


//4자리 10진수를 입력받아 자리수별로 나누어 출력하는 모듈
module bcd_data_parse (
    input [13:0] data,
    output reg [3:0] hex_value_0, hex_value_1, hex_value_2, hex_value_3
);
    always @(data)  begin
        hex_value_0 =  data         % 10;  //1의자리수 계산
        hex_value_1 = (data / 10)   % 10;  //10의자리수 계산
        hex_value_2 = (data / 100)  % 10;  //100의자리수 계산
        hex_value_3 = (data / 1000) % 10;  //1000의자리수 계산
    end
endmodule




module hex_to_dec (
    input clk, reset_p,
    input [15:0] in_hex_data,
    output reg [15:0] out_dec_num
    );

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) out_dec_num = 0; 
        else begin             
            out_dec_num[ 3: 0] = (in_hex_data%10);        // 1의 자리수
            out_dec_num[ 7: 4] = ((in_hex_data/10)%10);   // 10의 자리수 
            out_dec_num[11: 8] = ((in_hex_data/100)%10);  // 100의 자리수
            out_dec_num[15:12] = (in_hex_data/1000);      // 1000의 자리수
        end
    end
    
endmodule


//클록분주 + 엣지검출
module clock_div_Nbit #(
    parameter N = 20 //20bit
    )(
    input clk, reset_p,
    output clk_div_n
    );

    reg [N-1:0] clk_temp;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) clk_temp=0;
        else clk_temp = clk_temp + 1;
    end

    edge_detector_p  ed_clk (clk, reset_p, clk_temp[N-1], clk_div_n);
endmodule


module button_test_seg7_123123 (
    input clk, reset_p,
    input [3:0] btn, 
    output [7:0] segment_out,
    output [3:0] com_sel
    ); 

    //버튼입력 감지 , +디바운싱 +엣지검출 +상승엣지펄스출력
    wire [3:0] btn_p;
    genvar i;
    generate
        // i : 0, 1, 2, 3
        for ( i=0; i<4; i=i+1 ) begin : btn_cntr // gen block의 이름 => 인스턴스 생성시 이름 btn_cntr[0]~[3]
            button_cntr btcntr (clk, reset_p, btn[i], btn_p[i]);
        end
    endgenerate

    //버튼입력시 카운터 증가/감소/시프트
    reg [15:0] btn_counter;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) btn_counter = 0;
        else begin
            case (btn_p)
                4'b0001 : btn_counter = btn_counter + 1;
                4'b0010 : btn_counter = btn_counter - 1;
                4'b0100 : btn_counter = btn_counter >> 1;
                4'b1000 : btn_counter = btn_counter << 1;
                default : btn_counter = btn_counter;
            endcase
        end 
    end

    //FND 4자리 출력
    fnd_4_digit_cntr fnd_0 (.clk(clk), .reset_p(reset_p), .value(btn_counter), .segment_data_ca(segment_out), .com_sel(com_sel));

endmodule

