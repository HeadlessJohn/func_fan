`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2024 01:52:45 PM
// Design Name: 
// Module Name: timer_controller
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

/*
module cook_timer_core_ (
    input clk, reset_p,
    input [3:0] btn_edge,
    // 0 : start/stop , 1 : inc sec, 2 : inc min, 3 : restart
    output [15:0] time_digit,  
    output led,
    output buz_clk );

    wire clk_usec, clk_msec, clk_sec;
    wire run;
    wire btn_inc_tgt_sec_p, btn_inc_tgt_min_p;
    wire clk_under_flow_sec_1, clk_under_flow_sec_10, clk_under_flow_min_1;
    wire [3:0] sec_1, sec_10, min_1, min_10;

    assign reset = reset_p | btn_edge[3];
    assign clk_run = (run & ~led) ? clk : 1'b0;
    assign btn_inc_tgt_sec_p = run ? 1'b0 : btn_edge[1];
    assign btn_inc_tgt_min_p = run ? 1'b0 : btn_edge[2];
    assign led = (run & (min_10|min_1|sec_10|sec_1) == 0) ? 1'b1 : 1'b0;
    
    reg [16:0] clk_div;
    always @ (posedge clk) clk_div = clk_div + 1;
    assign buz_clk = led ? clk_div[12] : 1'b0;  //12 : 15.26khz

    T_flip_flop_p TFF_run (clk, reset, btn_edge[0], run);

    clock_usec     clk_us (clk_run, reset, clk_usec);           // sysclk -> 1us
    clock_div_1000 clk_ms (clk_run, reset, clk_usec, clk_msec); // 1us -> 1ms
    clock_div_1000 clk_s  (clk_run, reset, clk_msec, clk_sec);  // 1ms -> 1s

    load_count_ud_N #(10) sec_1_cnt (.clk            (clk),
                                     .reset_p        (reset),
                                     .clk_up         (btn_inc_tgt_sec_p),
                                     .clk_dn         (clk_sec),
                                     .digit          (sec_1),
                                     .clk_over_flow  (clk_over_flow_sec_1),
                                     .clk_under_flow (clk_under_flow_sec_1) );
    load_count_ud_N #(6) sec_10_cnt (.clk            (clk),
                                     .reset_p        (reset),
                                     .clk_up         (clk_over_flow_sec_1),
                                     .clk_dn         (clk_under_flow_sec_1),
                                     .digit          (sec_10),
                                    //  .clk_over_flow(clk_over_flow_min_1), 
                                    // 버튼으로 세팅시 오버플로우 발생 비활성화
                                     .clk_under_flow (clk_under_flow_sec_10)   );
    load_count_ud_N #(10) min_1_cnt (.clk            (clk),
                                     .reset_p        (reset),
                                     .clk_up         (btn_inc_tgt_min_p),
                                     .clk_dn         (clk_under_flow_sec_10),
                                     .digit          (min_1),
                                     .clk_over_flow  (clk_over_flow_min_1),
                                     .clk_under_flow (clk_under_flow_min_1) );
    load_count_ud_N #(10) min_10_cnt(.clk            (clk),
                                     .reset_p        (reset),
                                     .clk_up         (clk_over_flow_min_1),
                                     .clk_dn         (clk_under_flow_min_1),
                                     .digit          (min_10) );
    assign time_digit = {min_10, min_1, sec_10, sec_1};                                     
endmodule
*/

module timer_controller #(
    parameter SYS_FREQ = 125
    ) (
    input clk, reset_p,
    input btn,
    input timer_en,
    output [7:0] seg_7,
    output [3:0] com    );

    //state 정의
    localparam S_IDLE          = 4'b0001;
    localparam S_SET_1H        = 4'b0010;
    localparam S_SET_3H        = 4'b0100;
    localparam S_SET_5H        = 4'b1000;

    // 버튼 입력부 컨트롤러
    wire btn_p, btn_n;
    button_cntr btn0(clk, reset_p, btn, btn_p, btn_n);

    //1초 클록 생성
    wire clk_usec, clk_msec, clk_sec;
    clock_usec #(12) clk_us0 (clk, reset_p, clk_usec);
    clock_div_1000         clk_ms0 (clk, reset_p, clk_usec, clk_msec);
    clock_div_1000         clk_s0  (clk, reset_p, clk_msec, clk_sec);
    
    // FSM 
    reg [3:0] state;
    reg [3:0] next_state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    // btn 입력에 따른 state 변경 로직
    reg data_load;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= S_IDLE;
        end
        else begin
            if (timer_en) begin
                if (btn_p) begin // 버튼을 누를때 state 변경
                    next_state <= {state[2:0], state[3]}; // state를 1비트씩 shift하여 다음 state로 이동
                end 
                else if (btn_n) begin
                    data_load <= 1; // 버튼을 뗄 때 데이터 로드
                end
                else begin
                    data_load <= 0; // 이외의 경우 0을 줌
                end
            end
            else begin
                next_state <= S_IDLE;
            end
        end
    end

    // set_value 설정
    reg [3:0] set_value = 0;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            set_value <= 0;
        end
        else begin
            case (state)
                S_IDLE : begin // Hour
                    set_value <= 0;
                end

                S_SET_1H : begin
                    set_value <= 1;
                end

                S_SET_3H : begin
                    set_value <= 3;
                end

                S_SET_5H : begin
                    set_value <= 5;
                end
            endcase
        end
    end

    //
    wire [3:0] sec_1, sec_10, min_1, min_10, hr_1;
    wire clk_sec_1_uf, clk_sec_10_uf, clk_min_1_uf, clk_min_10_uf;

    wire clk_sec_out;
    wire clk_en;
    assign clk_sec_out = clk_en ? clk_sec : 1'b0; //clk_en이 1이면 clk_sec를 출력하여 다운카운터를 동작하게함
    assign clk_en = ({sec_1, sec_10, min_1, min_10, hr_1} == 0) ? 1'b0 : 1'b1; // 카운터가 0이 되면 clk_en을 0으로 하여 카운터를 멈춤

    load_count_ud_N #(10) timer_sec_1( .clk            (clk),
                                       .reset_p        (reset_p),
                                       .clk_dn         (clk_sec_out),    // 숫자를 내릴 신호 1펄스 입력
                                       .data_load      (data_load),      // data_load 신호 1펄스 입력
                                       .set_value      (4'b0),           // 설정할 값 4비트 이진 데이터
                                       .digit          (sec_1),          // 출력할 숫자 4비트 이진 데이터
                                       .clk_under_flow (clk_sec_1_uf) ); // underflow되면 1펄스 출력
                                    
    load_count_ud_N #(6) timer_sec_10( .clk            (clk),
                                       .reset_p        (reset_p),
                                       .clk_dn         (clk_sec_1_uf), 
                                       .data_load      (data_load),   
                                       .set_value      (4'b0),        
                                       .digit          (sec_10),      
                                       .clk_under_flow (clk_sec_10_uf) );

    load_count_ud_N #(10) timer_min_1( .clk            (clk),
                                       .reset_p        (reset_p),
                                       .clk_dn         (clk_sec_10_uf),
                                       .data_load      (data_load),  
                                       .set_value      (4'b0),       
                                       .digit          (min_1),      
                                       .clk_under_flow (clk_min_1_uf) );  

    load_count_ud_N #(6) timer_min_10( .clk            (clk),
                                       .reset_p        (reset_p),
                                       .clk_dn         (clk_min_1_uf),
                                       .data_load      (data_load),   
                                       .set_value      (4'b0),        
                                       .digit          (min_10),      
                                       .clk_under_flow (clk_min_10_uf) );          

    load_count_ud_N #(10) timer_hr_1 ( .clk            (clk),
                                       .reset_p        (reset_p),
                                       .clk_dn         (clk_min_10_uf),
                                       .data_load      (data_load),   
                                       .set_value      (set_value),        
                                       .digit          (hr_1) );                                       

    //디버깅용 모듈
    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset_p), 
                               .value           ({4'b0, hr_1, min_10, min_1}),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );
endmodule