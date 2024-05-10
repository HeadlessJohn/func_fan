`timescale 1ns / 1ps


module half_adder_structural(  // ????
    input A, B, // ??
    output sum, carry // ??
    );
    
    xor(sum, A, B); // sum = A^B
    and(carry, A, B); // carry = A*B
    
endmodule
    
    
// ??? ???
module half_adder_behavioral(
    input A, B,
    output reg sum, carry // register (???) ?? ?? ? ???
    );
    
    always @ (A, B) begin //A,B ? ?? ??? ??
        case ( {A, B} ) // {A,B} = ??? ??, ?? ???? ??? ??? ?
            2'b00: begin sum=0; carry=0; end // nbit'binary,?? : begin ?? end 
            2'b01: begin sum=1; carry=0; end
            2'b10: begin sum=1; carry=0; end
            2'b11: begin sum=0; carry=1; end
        endcase
    end

endmodule

// ??? ??? ???
module half_adder_dataflow(
    input A,B,
    output sum, carry
    );
    
    wire [1:0] sum_value; // 2?? ??
    
    assign sum_value = A + B; // A+B? sum_value? ?? 2???? ??
    assign sum = sum_value[0]; // ??? ?? = sum
    assign carry = sum_value[1]; // ??? ?? = carry
    
endmodule

//???-??????
module full_adder_structural(
    input A, B, Cin, //???? ??
    output sum, carry ); // ???? ??
    
    //????? ??? ???
    wire sum_0; 
    wire carry_0;
    wire carry_1;
    
    //????? ???? ??
    //  .A = half_adder? ??A   (A) = full_adder? ??A    .A(A) = .A? A?  wire? ????? ?
    half_adder_structural ha0 (.A(A), .B(B), .sum(sum_0), .carry(carry_0) );   
    half_adder_structural ha1 (.A(sum_0), .B(Cin), .sum(sum), .carry(carry_1) );
    
    //?? ??? or gate
    or(carry, carry_0, carry_1);
endmodule

//???-??????
module full_adder_behavioral(
    input A, B, Cin, //???? ?? 
    output reg sum, carry ); // ???? ??, reg type? ?? ??(always? ?? ??? reg) ???? ??? wire type
    
    always @(A, B, Cin) begin // A, B, Cin?? ????  ??
        case ( {A, B, Cin} ) // ?? ??? ?? ??,  A, B, Cin? ?? 3??? ??
            3'b000 : begin sum =0; carry =0; end
            3'b001 : begin sum =1; carry =0; end
            3'b010 : begin sum =1; carry =0; end
            3'b011 : begin sum =0; carry =1; end
            3'b100 : begin sum =1; carry =0; end
            3'b101 : begin sum =0; carry =1; end
            3'b110 : begin sum =0; carry =1; end
            3'b111 : begin sum =1; carry =1; end
        endcase
    end
endmodule

//???-?????????
module full_adder_dataflow(
    input A, B, Cin,
    output sum, carry );
    
    wire [1:0] sum_value; // 2?? ??
    
    assign sum_value = A + B + Cin; // A+B? sum_value? ?? 2???? ??
    assign sum = sum_value[0]; // ??? ?? = sum
    assign carry = sum_value[1]; // ??? ?? = carry
    
endmodule

//4bit ???
module full_adder_4bit_s(
    input [3:0] A, B,
    supply0 Cin,
    output [3:0] sum, 
    output carry 
    );
    
    //???? ??? ???
    wire cout_0;
    wire cout_1;
    wire cout_2;
    
    //???? ???? ??
    full_adder_structural fa0 (.A(A[0]), .B(B[0]), .sum(sum[0]), .Cin(Cin), .carry(cout_0));
    full_adder_structural fa1 (.A(A[1]), .B(B[1]), .sum(sum[1]), .Cin(cout_0), .carry(cout_1));
    full_adder_structural fa2 (.A(A[2]), .B(B[2]), .sum(sum[2]), .Cin(cout_1), .carry(cout_2));
    full_adder_structural fa3 (.A(A[3]), .B(B[3]), .sum(sum[3]), .Cin(cout_2), .carry(carry));
    
endmodule

//???-????????? 
module full_adder_4bit(
    input [3:0] A, B, //4??? A, B ??
    input Cin,  //?? ??
    output [3:0] sum, //4??? ?? ??
    output carry // ?? ?? ???
    );
    
    wire [4:0] temp; //??? 1+4?? ?? ??
    
    assign temp = A + B + Cin; //A+B+Cin? temp? ??
    assign sum = temp[3:0]; //??4??? sum
    assign carry = temp[4]; //??1??? carry? ??
    
endmodule

//???-16bit-????????? 
module full_adder_16bit(
    input [15:0] A, B, //16??? A, B ??
    input Cin,  //?? ??
    output [15:0] sum, //16??? ?? ??
    output carry // ?? ?? ???
    );
    
    wire [16:0] temp; //??? 1+16?? ?? ??
    
    assign temp = A + B + Cin; //A+B+Cin? temp? ??
    assign sum = temp[15:0]; //??16??? sum
    assign carry = temp[16]; //??1??? carry? ??
    
endmodule

//????-??????
module full_add_sub_s(
    input [3:0] A, B, //4??? A, B ??
    input s,  //?? : s=0,  ?? : s=1
    output [3:0] sum, //4??? ?? ??
    output carry // ?? ?? ???
    );
     
    wire cout_0;
    wire cout_1;
    wire cout_2;   

//    ^ : xor  
//    & : and 
//    | : or 
//    ~ : not
    
    full_adder_structural fa0 (.A(A[0]), .B(B[0]^s), .sum(sum[0]), .Cin(s), .carry(cout_0));
    full_adder_structural fa1 (.A(A[1]), .B(B[1]^s), .sum(sum[1]), .Cin(cout_0), .carry(cout_1));
    full_adder_structural fa2 (.A(A[2]), .B(B[2]^s), .sum(sum[2]), .Cin(cout_1), .carry(cout_2));
    full_adder_structural fa3 (.A(A[3]), .B(B[3]^s), .sum(sum[3]), .Cin(cout_2), .carry(carry));
endmodule


//????-????????? 
module full_add_sub_4bit(
    input [3:0] A, B, //4??? A, B ??
    input s, // ?? ?? ?? ??
    output [3:0] sum, //4??? ?? ??
    output carry // ?? ?? ???
    );
    
    wire [4:0] temp; //??? 1+4?? ?? ??
    
    assign temp = s ? A - B : A + B; //  S? ???? s=A-B,  S? ??? ?? s=A+B
    assign sum = temp[3:0]; //??4??? sum
    assign carry = ~temp[4]; //??1??? carry? ??

    //??? ???? ??? ?? 1? ???? ??? ??
    //ex) 1111 -> 8bit? ???? -> 00001111 -> ??? ????
    //ex) 1111 -> 8bit? ???? -> 11111111 -> -1? ???? ??    
endmodule

//???? ?????
module tb_half_adder;
    reg a,b;

    half_adder_structural U0_half_adder(a, b, sum, cout);
    
    initial begin
            a=0; b=0;
        #10 a=1;
        #10 a=0; b=1;
        #10 a=1;
        #10 a=0; b=0;
        #10 $finish;
    end
endmodule