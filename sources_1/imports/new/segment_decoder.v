`timescale 1ns / 1ps

//BCD - 7-segment decoder
/*
     a
    ---
  f| g | b
    --- 
  e|   | c
    ---     .dot (p)
     d

0000_0000
abcd_efgp
0 : abcdef__ =    1111_1100
1 : _bc_____ =    0110_0000
2 : ab_de_g_ =    1101_1010
3 : abcd_g__ =    1111_0010
4 : _bc__fg_ =    0110_0110
5 : a_cd_fg_ =    1011_0110
6 : a_cdefg_ =    1011_1110
7 : abc_____ =    1110_0000
8 : abcdefg_ =    1111_1110
9 : abcd_fg_ =    1111_0110
a : abc_efg_ =    1110_1110
b : __cdefg_ =    0011_1110
c : a__def__ =    1001_1100
d : _bcde_g_ =    0111_1010
e : a__defg_ =    1001_1110
f : a___efg_ =    1000_1110
*/
// basys3 - common anode
// signal low = segment ON

module decoder_7seg (
    input [3:0] hex_value_0, hex_value_1, hex_value_2, hex_value_3, 
    input clk, //W5 : 100MHz
    output reg [7:0] segment_out,
    output reg [3:0] sel
);
    reg [3:0] hex_value;
    reg [17:0] clk_div;
    reg [1:0] cnt;
    always @(posedge clk) clk_div = clk_div + 1;
    always @(negedge clk_div[17]) cnt = cnt + 1;

    // cnt 0~1~2~3~0~1~2~3.... 100MHz / 2^18 = 381.47Hz
    // 4segment : 381.47Hz / 4 = 95.37Hz (T=10.49ms)
    // each segment need at least 60Hz (T=16.67ms)
    always @(cnt) begin
        case (cnt)
            2'b00 :
            begin
                sel = ~(4'b0001);
                hex_value = hex_value_0;
            end
            2'b01 : 
            begin
                sel = ~(4'b0010);
                hex_value = hex_value_1;
            end
            2'b10 : 
            begin
                sel = ~(4'b0100);
                hex_value = hex_value_2;
            end
            2'b11 : 
            begin
                sel = ~(4'b1000);
                hex_value = hex_value_3;
            end
        endcase

        case (hex_value) //segment font data
                                    // abcd_efgp
            4'b0000 : segment_out = 8'b1111_1100; //0
            4'b0001 : segment_out = 8'b0110_0000; //1
            4'b0011 : segment_out = 8'b1111_0010; //2
            4'b0010 : segment_out = 8'b1101_1010; //3

            4'b0100 : segment_out = 8'b0110_0110; //4
            4'b0101 : segment_out = 8'b1011_0110; //5
            4'b0110 : segment_out = 8'b1011_1110; //6
            4'b0111 : segment_out = 8'b1110_0000; //7

            4'b1000 : segment_out = 8'b1111_1110; //8
            4'b1001 : segment_out = 8'b1111_0110; //9
            4'b1010 : segment_out = 8'b1110_1110; //A
            4'b1011 : segment_out = 8'b0011_1110; //b

            4'b1100 : segment_out = 8'b1001_1100; //C
            4'b1101 : segment_out = 8'b0111_1010; //d
            4'b1110 : segment_out = 8'b1001_1110; //E
            4'b1111 : segment_out = 8'b1000_1110; //F
        endcase
        segment_out = ~segment_out; //invert signal for common anode
    end
endmodule


module seg_decoder(
    input clk, reset_p,
    input [3:0] ring_cnt,
    input [3:0] hex_value_0, hex_value_1, hex_value_2, hex_value_3, 
    output reg [7:0] segment_out,
    output reg [3:0] sel
);
    reg [3:0] hex_value;

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) hex_value = 0;
        else begin
            sel = ~ring_cnt;

            case (ring_cnt)
                4'b0001 : hex_value = hex_value_0;
                4'b0010 : hex_value = hex_value_1;
                4'b0100 : hex_value = hex_value_2;
                default : hex_value = hex_value_3;
            endcase

            case (hex_value) //segment font data
                                        // abcd_efgp
                4'b0000 : segment_out = 8'b1111_1100; //0
                4'b0001 : segment_out = 8'b0110_0000; //1
                4'b0011 : segment_out = 8'b1111_0010; //2
                4'b0010 : segment_out = 8'b1101_1010; //3

                4'b0100 : segment_out = 8'b0110_0110; //4
                4'b0101 : segment_out = 8'b1011_0110; //5
                4'b0110 : segment_out = 8'b1011_1110; //6
                4'b0111 : segment_out = 8'b1110_0000; //7

                4'b1000 : segment_out = 8'b1111_1110; //8
                4'b1001 : segment_out = 8'b1111_0110; //9
                4'b1010 : segment_out = 8'b1110_1110; //A
                4'b1011 : segment_out = 8'b0011_1110; //b

                4'b1100 : segment_out = 8'b1001_1100; //C
                4'b1101 : segment_out = 8'b0111_1010; //d
                4'b1110 : segment_out = 8'b1001_1110; //E
                4'b1111 : segment_out = 8'b1000_1110; //F
            endcase
            segment_out = ~segment_out; //invert signal for common anode
        end
    end

endmodule

//FND 출력 모듈
module fnd_4_digit_cntr (
    input clk, reset_p,
    input [15:0] value,
    output [7:0] segment_data_an, segment_data_ca,
    output [3:0] com_sel
    );

    //------segment 출력
    wire [3:0] ring_cnt;
      //4개 출력용 4비트 링카운터
    ring_counter_Nbit #(4) ring_0 (clk, reset_p, ring_cnt);
    // ring_counter ring_0 (clk, reset_p, ring_cnt);
    seg_decoder seg_0 (clk, reset_p, ring_cnt, value[3:0], value[7:4], value[11:8], value[15:12], segment_data_an, com_sel);

    assign segment_data_ca = ~segment_data_an;
    
endmodule