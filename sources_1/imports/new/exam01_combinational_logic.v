`timescale 1ns / 1ps  // ?????? ??  1ps??? ?????, 1ns??? ???
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/22 12:17:01
// Design Name: 
// Module Name: exam01_combinational_logic
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

// and gate
module and_gate(
    input A,
    input B,
    output F
    );
     
    and(F, A, B); //and gate (??, ??1, ??2, ....)

endmodule



//??? : ??? ??? (??? ??)
//??? : ??? ??? (??? ??? ???)

// 2x4 ??? 
// B A  Y3 Y2 Y1 Y0
// 0 0   0  0  0  1
// 0 1   0  0  1  0
// 1 0   0  1  0  0
// 1 1   1  0  0  0

// Y0 = ~A * ~B
// Y1 = A * ~B
// Y2 = ~A * B
// Y3 = A * B

module decoder_test (
    input A, B,
    output reg [3:0] Y
    );
    
    always @ (A, B) begin
        Y[0] = ~A * ~B;
        Y[1] = A * ~B;
        Y[2] = ~A * B;
        Y[3] = A * B;
    end
endmodule

module decoder_b (
    input A, B,
    output reg [3:0] Y
    );

    always @ (B, A) begin // A, B?? ????  ??
        case ( {B, A} ) // ?? ??? ?? ??,  A, B? ?? 2??? ??
                        // {A,B} = BA (????? ???)
             //AB              Y3210
            2'b00 : begin Y= 4'b0001; end
            2'b01 : begin Y= 4'b0010; end
            2'b10 : begin Y= 4'b0100; end
            2'b11 : begin Y= 4'b1000; end
        endcase
    end
endmodule

module decoder_s (
    input [1:0] code,
    output [3:0] signal
    );

    wire [1:0] code_bar;

    not (code_bar[0], code[0]); // 0???(A)? ????
    not (code_bar[1], code[1]); // 1???(B)? ????
                           //B               A
    and (signal[0], code_bar[1],    code_bar[0]);  // signal[0] = ~B * ~A
    and (signal[1], code_bar[1],        code[0]);  // signal[1] = ~B *  A
    and (signal[2],     code[1],    code_bar[0]);  // signal[2] =  B * ~A
    and (signal[3],     code[1],        code[0]);  // signal[3] =  B *  A

endmodule

module decoder_2_4_b (
    input [1:0] code,
    output reg [3:0] signal
    );
    //??? ???? ???? ??
    always @ (code) begin
        if      (code == 2'b00) signal = 4'b0001;
        else if (code == 2'b01) signal = 4'b0010;
        else if (code == 2'b10) signal = 4'b0100;
        else                    signal = 4'b1000;

        // case(code)
        //     2'b00 : signal = 4'b0001;
        //     2'b01 : signal = 4'b0010;
        //     2'b10 : signal = 4'b0100;
        //     2'b11 : signal = 4'b1000;
        // endcase
    end
endmodule

module decoder_2_4_d (
    input [1:0] code,
    output [3:0] signal
    );
    
    assign signal = (code == 2'b00) ? 4'b0001 : 
                    (code == 2'b01) ? 4'b0010 : 
                    (code == 2'b10) ? 4'b0100 : 
                                      4'b1000 ;
endmodule

module  endocer_4_2 (
    input   [3:0] signal,
    output  [1:0] code
    );

    // 1? 2???? ??? ??? ??? ??? ??? ??? ??
    assign code = (signal == 4'b0001) ? 2'b00 :
                  (signal == 4'b0010) ? 2'b01 :
                  (signal == 4'b0100) ? 2'b10 :
                                        2'b11 ;

endmodule


module D_ff (
    input clk, din, rst,
    output reg q
    );

    always @(posedge clk or posedge rst) begin
        if (rst==1) q <= 1'b0;
        else q <= din;
    end 

endmodule

module string_test ;
    // ???? unsigned  ??? ?? ??
    // 8bit*???? ??? ?? ??
    reg [8*14:1] string_var;

    initial begin
        string_var = "Hello world";
        $display("%s is stroed as %h", string_var, string_var);
        string_var = {string_var, "!!!"};
        $display("%s is stroed as %h", string_var, string_var);
        //(??)   Hello world is stroed as 00000048656c6c6f20776f726c64
        //Hello world!!! is stroed as 48656c6c6f20776f726c64212121
        //???? ?? ?? ??? ???? ???? ???
    end
    
endmodule




module decoder_2_4_en (
    input [1:0] code,
    input enable,
    output [3:0] signal
    );
    
    assign signal =         ~enable ? 4'b0000 : //enable? 0?? 0000?? 1?? ?? ?? ??
                    (code == 2'b00) ? 4'b0001 : 
                    (code == 2'b01) ? 4'b0010 : 
                    (code == 2'b10) ? 4'b0100 : 
                                      4'b1000 ;
endmodule

module decoder_3_8 (
    input [2:0] code,
    output [7:0] signal
    );

    decoder_2_4_en dec_low  (.code(code[1:0]), .enable(~code[2]), .signal(signal[3:0]));
    decoder_2_4_en dec_high (.code(code[1:0]), .enable( code[2]), .signal(signal[7:4]));
endmodule

//2x4 enable ??? behavioral
module decoder_2_4_en_b (
    input [1:0] code, //2?? ??
    input enable,     //enable ??
    output reg [3:0] signal //4?? ??
    );
    
    always @(code, enable) begin
        case ( {enable, code} ) //enable 1?? ?? ON
            3'b000 : signal=4'b0000 ;
            3'b001 : signal=4'b0000 ;
            3'b010 : signal=4'b0000 ;
            3'b011 : signal=4'b0000 ;
            3'b100 : signal=4'b0001 ;
            3'b101 : signal=4'b0010 ;
            3'b110 : signal=4'b0100 ;
            3'b111 : signal=4'b1000 ;
        endcase
    end
endmodule

//3x8 ???
module decoder_3_8_hw (
    input [2:0] code,   //3?? ??
    output [7:0] signal //8?? ??
    );

    //enable=code[2] ? 0?? ???? ??, 1?? ???? ??
    decoder_2_4_en_b dec_high(.code(code[1:0]), .enable( code[2]), .signal(signal[7:4]));
    decoder_2_4_en_b dec_low (.code(code[1:0]), .enable(~code[2]), .signal(signal[3:0]));
endmodule 









