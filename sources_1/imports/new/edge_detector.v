`timescale 1ns / 1ps

module edge_detector_n (
    input clk, reset_p,
    input cp, 
    output p_edge, n_edge
    );
    
    reg ff_cur, ff_old;
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin 
            ff_cur <= 0;
            ff_old <= 0;
        end
        else begin
            ff_old <= ff_cur; // nonblocking 대입 연산자
            ff_cur <= cp;     // 연산이 병렬로 진행. 구문에 진입하면 우변의 값이 결정됨
        end
    end
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0; //게이트 대신 MUX로 설계
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule

module edge_detector_p (
    input clk, reset_p,
    input cp, 
    output p_edge, n_edge
    );
    
    reg ff_cur, ff_old;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin 
            ff_cur <= 0;
            ff_old <= 0;
        end
        else begin
            ff_old <= ff_cur; // nonblocking 대입 연산자
            ff_cur <= cp;     // 연산이 병렬로 진행. 구문에 진입하면 우변의 값이 결정됨
        end
    end
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0; //게이트 대신 MUX로 설계
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule

//버튼 입력 모듈 (디바운싱+엣지검출 1펄스 출력)
module button_cntr(
    input clk, reset_p,
    input btn,
    output btn_p_edge, btn_n_edge
    );

    //클록 디바이더
    reg [16:0] clk_div;
    always @(posedge clk, posedge reset_p)begin
        if (reset_p) begin
            clk_div <= 0;
        end
        else begin
            clk_div <= clk_div + 1;
        end
    end 

    //clk_div_16 엣지 검출
    wire clk_div_16;
    edge_detector_n ed1(clk, reset_p, clk_div[16], clk_div_16);

    //버튼 입력 디바운싱 DFF, 1ms
    reg debounced_btn;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) debounced_btn <= 0;
        else if (clk_div_16) debounced_btn <= btn;
    end

    //버튼입력 엣지 검출, 상승/하강 엣지
    edge_detector_n ed2(clk, reset_p, debounced_btn, btn_p_edge, btn_n_edge);
endmodule