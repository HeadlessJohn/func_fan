`timescale 1ns / 1ps

module led_matrix_decoder (
    input clk, reset_p,
    input [63:0] fontdata,      //8x8
    output reg [7:0] led_col, // x좌표 low active
    output reg [7:0] led_row  // y좌표 high active
    );

    //클록 분주기 + edge detect
    wire clk_div_16;
    clock_div_Nbit #(16) clk_div_16b(clk, reset_p, clk_div_16);

    //링카운터 8비트 
    wire [7:0] ring_cnt;
    ring_counter_Nbit #(8) ring_8b_0 (clk, reset_p, ring_cnt);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) led_row = 8'b0000_0000;
        else begin
            case (ring_cnt)//cnt->row,   
                8'b1000_0000 : led_col = ~(fontdata[63:56]);
                8'b0100_0000 : led_col = ~(fontdata[55:48]);
                8'b0010_0000 : led_col = ~(fontdata[47:40]);
                8'b0001_0000 : led_col = ~(fontdata[39:32]);
                8'b0000_1000 : led_col = ~(fontdata[31:24]);
                8'b0000_0100 : led_col = ~(fontdata[23:16]);
                8'b0000_0010 : led_col = ~(fontdata[15: 8]);
                8'b0000_0001 : led_col = ~(fontdata[ 7: 0]);
                default : led_col = ~(8'b0000_0000);
            endcase
            led_row = ring_cnt;
        end
    end
endmodule

module led_matrix_8x8 (
    input clk, reset_p,
    input [3:0] btn,
    output [7:0] led_col,
    output [7:0] led_row
    );
    reg [63:0] fontdata;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) fontdata = 0;
        else begin
            case (btn)
                4'b0000 : fontdata = 64'h3c66666e76663c00; // 0
                4'b0001 : fontdata = 64'h7e1818181c181800; // 1
                4'b0010 : fontdata = 64'h7e060c3060663c00; // 2
                4'b0011 : fontdata = 64'h3c66603860663c00; // 3
                4'b0100 : fontdata = 64'h30307e3234383000; // 4
                4'b0101 : fontdata = 64'h3c6660603e067e00; // 5
                4'b0110 : fontdata = 64'h3c66663e06663c00; // 6
                4'b0111 : fontdata = 64'h1818183030667e00; // 7
                4'b1000 : fontdata = 64'h3c66663c66663c00; // 8
                4'b1001 : fontdata = 64'h3c66607c66663c00; // 9
                4'b1010 : fontdata = 64'h6666667e66663c00; // A
                4'b1011 : fontdata = 64'h3e66663e66663e00; // b
                4'b1100 : fontdata = 64'h3c66060606663c00; // C
                4'b1101 : fontdata = 64'h3e66666666663e00; // d
                4'b1110 : fontdata = 64'h7e06063e06067e00; // E
                4'b1111 : fontdata = 64'h0606063e06067e00; // F
            endcase
        end
        // if (clk_div[25]) fontdata = 64'h5555555555555555;
        // else             fontdata = 64'haaaaaaaaaaaaaaaa;
        // if (clk_div[25]) fontdata = 64'h1018fcfefc181000;
        // else             fontdata = 64'h10307efe7e301000;
    end
    // led 매트릭스 디코더 생성
    led_matrix_decoder led_mat_dec (clk, reset_p, fontdata, led_col, led_row);

endmodule
