`timescale 1ns / 1ps


module mux2b_if ( 
    input [1:0] in0, in1,
    input sel,
    output reg [1:0] out
);

    always @(sel, in0, in1) begin
        if (sel == 0) out = in0;
        else out = in1;
    end
    
endmodule

/*

4:1 MUX
      _____
D1 - |     |
D2 - | 4:1 |______
D3 - |     |
D4 - |     |
      _____
       | |
      S1 S2

*/
module mux_4_1 (
    input [3:0] data,
    input [1:0] sel,
    output qout
);
    // always @(data, sel) begin
    //     case (sel)
    //         2'b00 : qout = data[0];
    //         2'b01 : qout = data[1];
    //         2'b10 : qout = data[2];
    //         2'b11 : qout = data[3];
    //     endcase
    // end

    assign qout = data[sel];
endmodule

module mux_2_1 (
    input [1:0] d,
    input s,
    output f
);
    assign f= s? d[1] : d[0] ;
    // wire sbar, w0, w1;

    // not (sbar, s);
    // and (w0, sbar, d[0]);
    // and (w1, s, d[1]);
    // or (f, w0, w1);
    // // if s=0 -> f=d[0],  s=1 -> f=d[1]
    
endmodule


module mux_8_1 (
    input [7:0] data,
    input [2:0] sel,
    output qout
);
    // always @(data, sel) begin
    //     case (sel)
    //         2'b00 : qout = data[0];
    //         2'b01 : qout = data[1];
    //         2'b10 : qout = data[2];
    //         2'b11 : qout = data[3];
    //     endcase
    // end

    assign qout = data[sel];
endmodule


// Look Up Table
// MUX로 구성한 조합회로
// FPGA 내부에는 LUT가 다수 존재
// 동작적 모델링이 가장 적합
// ex) always문, case

module demux_1_4 (
    input d,
    input [1:0] s,
    output [3:0] f
);
    // s=0 -> 000d
    // s=1 -> 00d0
    // s=2 -> 0d00
    // s=3 -> d000
    assign f = (s == 2'b00) ? {3'b000, d}      : 
               (s == 2'b01) ? {2'b00, d, 1'b0} :
               (s == 2'b10) ? {1'b0, d, 2'b00} :
                              {d, 3'b000}      ;
endmodule


module mux_demux (
    input [7:0] d,
    input [2:0] s_mux,
    input [1:0] s_demux,
    output [3:0] f
);
    wire mux_out;
    mux_8_1 mux0 (d, s_mux, mux_out);
    demux_1_4 demux0 (mux_out, s_demux, f);
    
endmodule

// 십진화 이진 코드 변환
module bin_to_dec(
        input [11:0] bin,     // 9999 =   10_0111_0000_1111
        output reg [15:0] bcd //      = 1001_1001_1001_1001
    );
    reg [3:0] i;
    always @(bin) begin
        bcd = 0;
        // 10 이상일경우 6을 더해 윗자리로 만든다
        // ex: 11 = 0000_1011   +6 ->  17 = 0001_0111
        for (i = 0; i < 12; i = i+1)begin
            bcd = {bcd[14:0], bin[11-i]};
            if(i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if(i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if(i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if(i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule

/*
0000_0000   00
0000_0001   01
0000_0010   02
0000_0011   03
0000_0100   04
0000_0101   05
0000_0110   06
0000_0111   07
0000_1000   08
0000_1001   09

0001_0000   10   10부터 다음 4자리로 이동
0001_0001   11   앞4자리 뒤4자리 잘라서 읽기
0001_0010   12
...
*/