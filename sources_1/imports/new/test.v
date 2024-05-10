`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/05 23:07:09
// Design Name: 
// Module Name: test
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


module non_blk1(
    output out,
    reg a, b, clk);

    initial begin
        a = 0;
        b = 1;
        clk = 0;
    end

    always clk = #5 ~clk;
    
    always @(posedge clk) begin
        // nonblocking : 우변의 값을 미리 정하고 연산
        // FF의 출력으로 대응됨 (값을 저장하는 기능)
        a <= b;  //a=b=1,0,1,0...
        b <= a;  //b=a=0,1,0,1...
        // FF 2개 생성
    end
endmodule

module blk1(
    output out,
    reg a, b, clk);

    initial begin
        a = 0;
        b = 1;
        clk = 0;
    end

    always clk = #5 ~clk;
    
    always @(posedge clk) begin
        a = b; // a=b 
        b = a; // b=a  둘다 1임
        // FF 1개 생성
    end
endmodule

module dff_sr_async (
    input clk, d, rb, sb,
    output reg q,
    output qb
);
    always @(posedge clk , negedge rb, negedge sb) begin
        if (rb == 0) q <= 0;
        else if (sb ==0) q <= 1;
        else q <= d;
        // qb = ~q;    //always문 내부로 작성할 경우 FF 1개 증가함
    end

    assign  qb = ~q;
endmodule


module multiplier_8b #(
    parameter SIZE = 8, 
    parameter LongSize = 2*SIZE
) (
    input      [SIZE-1 : 0]        opa, opb,
    output reg [LongSize-1 : 0]    result
);
    reg     [LongSize-1 : 0]    shift_opa, shift_opb;

    always @(opa or opb) begin
        shift_opa = opa;
        shift_opb = opb;
        result = 0;
        repeat(SIZE) begin
            if(shift_opb[0]) result = result + shift_opa;
            shift_opa = shift_opa << 1;
            shift_opb = shift_opb >> 1;
        end
    end
endmodule

module enc_for (
    input   [7:0] in,
    output reg [2:0] out,
    integer i
    );

    always @(in) begin : LOOP
        out = 0;
        for(i=7; i>=0; i=i-1) begin
            if(in[i]) begin
                out=i;
                disable LOOP; //Lable, 반복 종료 후 동일한 Lable의 위치로 이동 ->always문 종료하게됨
            end
        end
    end
    
endmodule

module d_latch_8bit (   
    input [7:0] d,
    input clk, set, reset,
    output reg [7:0] q
    );
    always @(clk, d, set, reset) begin
        if(!reset) q=1'b0;
        else if (!set) q=1'b1;
        else if (clk) q=d;
        else q=q;
    end
endmodule

module tb_d_latch();
    reg set, reset, d;
    reg clk;

    d_latch_8bit tb0 (d, clk, set, reset, q);

    initial begin
        set = 1;
        reset = 1;
        d = 0;
        clk = 0;
        forever #10 clk = ~clk;
    end

    always begin #88 d = ~d; end
    always begin 
        #1000 set = 0;
        #5 set = 1;
    end

    always begin
        #1500 reset = 0;
        #5 reset = 1;
    end

endmodule

module latch_blk (
    input en, a, b, c,
    output reg y
    );

    reg m;
    always @(en, a, b, c) begin
        if(en) begin
            m <= ~(a|b);
            y <= ~(m&c);
        end
    end
endmodule


// TXCK의 rising edge를 검출
// TXCK의 rising edge에서 TSTART의 rising edge를 검출
// TXCK의 rising edge에서 
//  - TSTART의 rising edge를 검출
//      1. TXPD를 TPD로 복사
//      2. BCNT를 초기화
//      3. TXSD를 low로 설정 (start bit)
//  - 그 외에 BCNT가 8보다 작으면
//      1. BCNT를 증가시킨다.
//      2. TPD[7:0]을 순서대로 출력.
//  - BCNT가 8이면
//      1. BCNT를 15로 설정
//      2. TXSD를 high로 설정 (stop bit)

// start bit는 0, stop bit는 1
// 8bit 데이터 LSB부터 출력 
module UART_TX(
    input clk, reset_p,
    input txck, tstart,
    input [7:0] txpd,
    output reg txsd    );

    reg [7:0] tpd;
    reg [3:0] bcnt;

    //txck의 rising edge 검출
    edge_detector_n ed_txck(clk, reset_p, txck, txck_p);

    //tstart가 입력되면 tpd에 txpd를 복사
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            bcnt <= 4'hF;
            tpd <= 8'hFF;
            txsd <= 1;
        end
        else if (txck_p) begin
            if (tstart) begin
                tpd <= txpd;
                bcnt <= 0;
                txsd <= 0; //start bit
                $display("start bit");
            end
            else if (bcnt < 8) begin
                bcnt <= bcnt + 1;
                txsd <= tpd[bcnt];//lsb부터 tpd의 0~7출력
                $display("data bit %d", txsd);
            end
            else begin
                bcnt <= 15;
                txsd <= 1; //stop bit
                $display("stop bit");
            end
        end
    end
endmodule

//클록의 falling에서 데이터 
//9600hz
//1주기 104.167us
//125MHz의 13020.83 구간
//수신클록 한주기 counter는 13021
//6511에서 클록 반전
//13020에서 클록 반전
//start bit가
module UART_RX (
    input clk, reset_p,
    input rxsd,    
    output reg rxck,
    output reg [7:0] rdata    );

    //rxsd 엣지 검출
    wire rxsd_p, rxsd_n;
    edge_detector_n ed_rxsd(clk, reset_p, rxsd, rxsd_p, rxsd_n);
    
    //9600Hz 생성
    reg [13:0] rxck_cnt;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p || rxsd_n) begin //start bit 검출하면 rxck_cnt 초기화
            rxck_cnt <= 0;
            rxck <= 1; //high로 시작
        end
        else begin
            rxck_cnt <= rxck_cnt + 1;
            if (rxck_cnt == 6511) begin
                rxck <= ~rxck;
            end
            else if (rxck_cnt == 13021) begin
                rxck <= ~rxck;
            end
        end
    end

    //rxck 엣지 검출
    wire rxck_p, rxck_n;
    edge_detector_n ed_rxck(clk, reset_p, rxck, rxck_p, rxck_n);


    reg[3:0] rcnt;
    reg rx_start_flag;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            rcnt <= 15;
            rdata <= 8'hFF;
        end
        else begin //start bit가 들어오면
            if (rxsd_n) begin
                if (rcnt == 15) begin
                    rcnt <= 0;
                end
                else if(rcnt < 8) begin
                    rdata[rcnt] <= rxsd;
                    rcnt <= rcnt + 1;
                end
                else begin
                    rcnt <= 15;
                end
            end
        end
    end

endmodule

module tb_uart();
    reg clk, reset_p, txck, tstart;
    reg [7:0] txpd;
    wire [7:0] rdata;

    //100MHz 클록 생성
    always begin
        #5 clk = ~clk;
    end

    // txck 클록 생성
    // 1MHz
    always begin
        #72080 txck = ~txck;
    end

    UART_TX udt0(clk, reset_p, txck, tstart, txpd, txsd);
    UART_RX udt1(clk, reset_p, txsd, rxck, rdata);

    initial begin
        clk = 0;
        reset_p = 1;
        txck = 0;
        tstart = 0;
        txpd = 8'hAF; //1010 1111
    end

    initial begin
        #10   reset_p = 0;
        #100  tstart = 1;
        #300  tstart = 0;
    end

endmodule

