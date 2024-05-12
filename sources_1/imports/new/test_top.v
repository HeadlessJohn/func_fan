`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module button_test_seg7_dec (
    input clk, reset_p,
    input [3:0]btn, 
    output [7:0] segment_out,
    output [3:0] com_sel
    ); 

    reg [17:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;
    
    //clk_div_16 엣지검출
    wire clk_div_16;
    edge_detector_p  ed_clk_16 (clk, reset_p, clk_div[16], clk_div_16);

    //DFF 연결하여 버튼입력 1.28ms 디바운싱
    reg [3:0] btn_db;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) btn_db = 0;
        else if(clk_div_16) btn_db = btn;
    end

    //버튼입력 엣지검출
    wire [3:0]btn_p;
    edge_detector_p ed_btn0 (clk, reset_p, btn_db[0], btn_p[0]);
    edge_detector_p ed_btn1 (clk, reset_p, btn_db[1], btn_p[1]);
    edge_detector_p ed_btn2 (clk, reset_p, btn_db[2], btn_p[2]);
    edge_detector_p ed_btn3 (clk, reset_p, btn_db[3], btn_p[3]);

    //버튼입력시 카운터 증가
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
            btn_counter = (btn_counter > 9999) ? 9999 : btn_counter;
        end 
    end

    //segment 출력
    wire [7:0] segment_data;
    wire [3:0] ring_cnt;
    wire [15:0] btn_counter_dec;
    ring_counter_Nbit #(4) ring_0 (clk, reset_p, ring_cnt);
    hex_to_dec htd(clk, reset_p, btn_counter, btn_counter_dec);
    seg_decoder seg_0 (clk, reset_p, ring_cnt, 
                    btn_counter_dec[3:0], btn_counter_dec[7:4], btn_counter_dec[11:8], btn_counter_dec[15:12], 
                    segment_data, com_sel);

    assign segment_out = ~segment_data;
endmodule

module button_test_seg7 (
    input clk, reset_p,
    input [3:0]btn, 
    output [7:0] segment_out,
    output [3:0] com_sel
    ); 

    reg [17:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;
    
    //clk_div_16 엣지검출
    wire clk_div_16;
    edge_detector_p  ed_clk_16 (clk, reset_p, clk_div[16], clk_div_16);

    //DFF 연결하여 버튼입력 1.28ms 디바운싱
    reg [3:0] btn_db;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) btn_db = 0;
        else if(clk_div_16) btn_db = btn;
    end

    //버튼입력 엣지검출
    wire [3:0]btn_p;
    edge_detector_p ed_btn0 (clk, reset_p, btn_db[0], btn_p[0]);
    edge_detector_p ed_btn1 (clk, reset_p, btn_db[1], btn_p[1]);
    edge_detector_p ed_btn2 (clk, reset_p, btn_db[2], btn_p[2]);
    edge_detector_p ed_btn3 (clk, reset_p, btn_db[3], btn_p[3]);

    //버튼입력시 카운터 증가
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

    //segment 출력
    wire [7:0] segment_data;
    wire [3:0] ring_cnt;
    ring_counter_Nbit #(4) ring_0 (clk, reset_p, ring_cnt);
    seg_decoder seg_0 (clk, reset_p, ring_cnt, 
                    btn_counter[3:0], btn_counter[7:4], btn_counter[11:8], btn_counter[15:12], 
                    segment_data, com_sel);

    assign segment_out = ~segment_data;
endmodule

module led_bar_top (
    input clk, //reset_p,
    output [7:0] led_bar
    );
    
    reg [30:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    assign led_bar = ~clk_div[29:22];

endmodule

module button_test_top (
    input clk, reset_p, udsel, // 클록, 리셋, 업다운셀렉터
    input btnU,
    output [7:0] num_out, // 10진 숫자 데이터
    output [3:0] segsel  // 세그먼트 셀렉터
    ); 
    
    reg [15:0] btn_counter;
    reg debounced_btn;
    wire [3:0] ring_cnt;
    wire btnU_p_edge;

    //클록 디바이더
    reg [20:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;

    //clk_div[16]의 엣지를 검출
    edge_detector_n ed0(clk, reset_p, clk_div[16], clk_div_16);

    //1ms에 1번만 btnU의 신호를 받음 
    //clk 1.28ms의 DFF 연결
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) debounced_btn = 0; //reset 우선 
        else if(clk_div_16) debounced_btn = btnU;
    end

    //DFF에서 디바운싱된 버튼입력의 엣지를 검출
    edge_detector_n ed1(clk, reset_p, debounced_btn, btnU_p_edge);

    //always문 감지신호에 clk, reset만 넣는게 동기에 중요함
    //버튼 입력 감지하여 카운터 증가
    always @(posedge clk, posedge reset_p) begin 
        if(reset_p) btn_counter = 0;
        else begin
            if(btnU_p_edge) btn_counter = udsel ? btn_counter + 1 : btn_counter - 1;
        end
    end

    ring_counter ring_0 (clk_div_16, ring_cnt);
    seg_decoder decoder_0 (clk, reset_p, ring_cnt, btn_counter[3:0], btn_counter[7:4], btn_counter[11:8], btn_counter[15:12], num_out, segsel);
endmodule

module ring_counter_led_ (
    input clk, reset_p,
    output reg [15:0] led_signal
    );

    //클록 분주
    reg [25:0] clk_div;

    wire posedge_clk_div_20;    
    edge_detector_n ed(clk, reset_p, clk_div[25], posedge_clk_div_20);
    // 여러 always문에서 같은 변수의 값을 변경하면 문제 발생!!

    always @(posedge clk, posedge reset_p) begin
        //reset 우선 동작
        if (reset_p) clk_div = 0;
        else clk_div = clk_div + 1;
    end
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            led_signal = 16'b1; //초기화시 1로, power on reset
        end
        else begin
            if (posedge_clk_div_20) begin 
                led_signal = {led_signal[14:0], led_signal[15]}; // ring shift
            end
        end
    end
endmodule

module ring_counter_led (
    input clk, reset_p,
    output reg [15:0] led_signal
    );

    //클록 분주
    reg [21:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;

    reg right_flag; //방향전환 플래그

    always @(posedge clk_div[21], posedge reset_p) begin
        if (reset_p) led_signal = 16'b0; //초기화시 모두 꺼짐
        else begin 
            if (led_signal == 16'b0) begin //초기화 직후 1로 만듦, 플래그 0
                right_flag = 0; 
                led_signal = 16'b1; 
            end 
            else led_signal = right_flag ? led_signal >> 1 : led_signal << 1; //좌우로 1비트 쉬프트
            if (led_signal == 16'b1000_0000_0000_0000) right_flag = 1; //방향전환
            if (led_signal == 16'b1) right_flag = 0; //방향전환
        end
    end
    
endmodule

module segment_up_down_counter (
    input clk, reset_p, udsel, // 클록, 리셋, 업다운셀렉터
    output [7:0] num_out, // 10진 숫자 데이터
    output [3:0] segsel,  // 세그먼트 셀렉터
    output [13:0] data //led출력
    ); 
    wire [3:0] ring_cnt;
    // wire [13:0] data;
    wire [3:0] digit_0, digit_1, digit_2, digit_3;
    reg [20:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;

    bcd_up_down_counter_p_9999 cnt9999 (clk_div[20], reset_p, udsel, data);
    bcd_data_parse parse0 (data, digit_0, digit_1, digit_2, digit_3);
    ring_counter ring0 (clk_div[15], ring_cnt);
    seg_decoder decoder_0 (clk, reset_p, ring_cnt, digit_0, digit_1, digit_2, digit_3, num_out, segsel);
endmodule

module up_counter_p_test (
    input clk, reset_p,
    output reg [15:0] count
    );  
    reg [19:0] clk_div;
    always @(posedge clk) clk_div=clk_div+1; 
    always @(posedge clk_div[19] or posedge reset_p) begin
        if(reset_p) count = 4'b0000;
        else count = count+1;
    end
endmodule


module bcd_up_down_counter_p_9999 (
    input clk, reset_p, sel, // 1 up, 0 down
    output reg [13:0] count
    );
    always @(posedge clk or posedge reset_p) begin // clk, reset의 상승엣지에서 작동
        if(reset_p) count = 0; // 초기화 입력
        else begin
            count = sel ? count+1 : count-1; // sel 1 일때 up,  0일때 down
            if      (count==10000) count=0; 
            else if (count==16383) count=9999; 
            else     count = count;
        end
    end
endmodule

module key_matrix_4x4_test_top (
    input clk, reset_p,
    input [3:0] row,

    output [3:0] col,
    output [7:0] segment_out,
    output [3:0] com_sel
    );
    reg [19:0] clk_div; // 1라인당 8ms, 4라인 32ms
    always @(posedge clk) clk_div = clk_div + 1;

    wire [3:0] key_value;
    wire key_valid;
    key_matrix_4x4 key_mat (clk, reset_p, row, col, key_value, key_valid);

    reg [15:0] cnt;
    wire key_valid_pe;
    edge_detector_p ed_valid(clk, reset_p, key_valid, key_valid_pe);

    reg clr, cal;
    reg [2:0] operator;
    always @(posedge clk, posedge reset_p)begin
        if (reset_p) cnt = 0;
        else if (key_valid_pe) begin
            case (key_value)
                4'h0 :    ; // 0
                4'h1 :    ; // 1
                4'h2 :    ; // 2 
                4'h3 :    ; // 3 
                4'h4 :    ; // 4 
                4'h5 :    ; // 5 
                4'h6 :    ; // 6 
                4'h7 :    ; // 7 
                4'h8 :    ; // 8 
                4'h9 :    ; // 9 
                4'ha : operator = 1; // + 
                4'hb : operator = 2; // - 
                4'hc : clr = 1;// clear
                4'hd : operator = 3; // / 
                4'he : operator = 4; // x 
                4'hf : cal = 1; // = 
                default : cnt = cnt ;
            endcase
        end
    end

    integer num_1, num_2;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p || clr) begin 
            operator = 0;
            num_1 = 0;
            num_2 = 0;
        end 
        else if (key_valid_pe) begin
            if (operator) num_2 = key_value;
            else num_1 = key_value;
        end
        else if (cal == 1) begin
            case (operator) 
                1 : cnt = num_1 + num_2;
                2 : cnt = num_1 - num_2;
                3 : cnt = num_1 / num_2;
                4 : cnt = num_1 * num_2;
                default : cnt = 0;
            endcase
        end
    end


    fnd_4_digit_cntr fnd_key_mat (.clk(clk), .reset_p(reset_p), .value(cnt), .segment_data_ca(segment_out), .com_sel(com_sel));
endmodule



module key_mat_test_sep_16 (
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [7:0] segment_out,
    output [3:0] com_sel
    );

    wire [15:0] key_value;
    key_matrix_4x4_seperate key_16(clk, reset_p, row, col, key_value);

    //엣지 디텍터
    wire [15:0] key_pedge;
    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1 ) begin : button_pe
            edge_detector_p (clk, reset_p, key_value[i], key_pedge[i]);
        end
    endgenerate

    //버튼 동작
    reg [15:0] cnt;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) cnt = 0;
        else if (key_pedge) begin
            case (key_pedge)
       /* S1 */ 16'h0001 : cnt = cnt + 1;
       /* S2 */ 16'h0002 : cnt = cnt + 2;
       /* S3 */ 16'h0004 : cnt = cnt + 3;
       /* S4 */ 16'h0008 : cnt = cnt + 4;

       /* S5 */ 16'h0010 : cnt = cnt + 5;
       /* S6 */ 16'h0020 : cnt = cnt + 6;
       /* S7 */ 16'h0040 : cnt = cnt + 7;
       /* S8 */ 16'h0080 : cnt = cnt + 8;

       /* S9 */ 16'h0100 : cnt = cnt - 1;
       /* S10*/ 16'h0200 : cnt = cnt - 2;
       /* S11*/ 16'h0400 : cnt = cnt - 3;
       /* S12*/ 16'h0800 : cnt = cnt - 4;

       /* S13*/ 16'h1000 : cnt = cnt - 5;
       /* S14*/ 16'h2000 : cnt = cnt - 6;
       /* S15*/ 16'h4000 : cnt = cnt - 7;
       /* S16*/ 16'h8000 : cnt = cnt - 8;
                default  : cnt = cnt;
            endcase
            // if (cnt >= 65535) cnt = 9999; // 언더플로우시 9999부터
            // else if (cnt >= 10000) cnt = 0; // 10000도달시 초기화
            // else cnt = cnt;
        end
    end
    
    //10진 변환 후 출력
    // wire [15:0] cnt_out;
    // hex_to_dec htd(clk, reset_p, cnt, cnt_out);
    fnd_4_digit_cntr fnd_4(.clk(clk), .reset_p(reset_p), .value(cnt), 
                        .segment_data_ca(segment_out), .com_sel(com_sel));

endmodule




module key_matrix_4x4_test_FSM (
    input clk, reset_p,
    input [3:0] row,

    output [3:0] col,
    output [7:0] segment_out,
    output [3:0] com_sel
    );
    reg [19:0] clk_div; // 1라인당 8ms, 4라인 32ms
    always @(posedge clk) clk_div = clk_div + 1;

    wire [3:0] key_value;
    wire key_valid;
    keypad_cntr_FSM key_fsm(clk, reset_p, row, col, key_value, key_valid);

    reg [15:0] cnt;
    wire key_valid_pe;
    edge_detector_p ed_valid(clk, reset_p, key_valid, key_valid_pe);

    always @(posedge clk, posedge reset_p)begin
        if (reset_p) cnt = 0;
        else if (key_valid_pe) begin
            case (key_value)
                // 4'h0 :    ; // 0
                // 4'h1 :    ; // 1
                // 4'h2 :    ; // 2 
                // 4'h3 :    ; // 3 
                // 4'h4 :    ; // 4 
                // 4'h5 :    ; // 5 
                // 4'h6 :    ; // 6 
                4'h7 :  cnt = cnt + 1 ; // 7 
                4'h8 :  cnt = cnt - 1 ; // 8 
                // 4'h9 :    ; // 9 
                // 4'ha :    ; // + 
                // 4'hb :    ; // - 
                // 4'hc :    ;// clear
                // 4'hd :    ; // / 
                // 4'he :    ; // x 
                // 4'hf :    ; // = 
                default : cnt = cnt ;
            endcase
        end
    end

    fnd_4_digit_cntr fnd_key_mat (.clk(clk), .reset_p(reset_p), .value(cnt), .segment_data_ca(segment_out), .com_sel(com_sel));
endmodule


module watch_func_top (
    input clk, reset_p,
    input [3:0] btn, //set, inc min, inc sec
    output [3:0] com,
    output [7:0] seg_7
    );

    //    1us,     1ms,       1s       1m
    wire clk_usec, clk_msec, clk_sec, clk_min;
    reg pause;

    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_0_p); // pause
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_1_p); // inc sec
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_2_p); // inc min
    // button_cntr btn_cntr_3 (clk, reset_p, btn[3], btn_3_p); // inc min

    //pause button
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) pause = 0;
        else if (btn_0_p) pause = ~pause; //toggle pause
    end

    clock_usec_pause clk_us_p (clk, reset_p, clk_usec, pause);    // sysclk -> 1us
    clock_div_1000 clk_ms     (clk, reset_p, clk_usec, clk_msec); // 1us -> 1ms
    clock_div_1000 clk_s      (clk, reset_p, clk_msec, clk_sec);  // 1ms -> 1s
    clock_min_pause clk_m     (clk, reset_p, clk_sec, clk_min, pause, btn_1_p);  // 1s -> 1m
    

    wire [3:0] sec_1, sec_10, min_1, min_10;
    counter_dec_60_up_down cnt_sec (clk, reset_p, clk_sec, sec_1, sec_10, pause, btn_1_p);
    counter_dec_60_up_down cnt_min (clk, reset_p, clk_min, min_1, min_10, pause, btn_2_p);
    
    fnd_4_digit_cntr fnd(.clk(clk), 
                         .reset_p(reset_p), 
                         .value({min_10, min_1, sec_10, sec_1}),
                         .segment_data_ca(seg_7), 
                         .com_sel(com));
endmodule



module watch_top (
    input clk, reset_p,
    input [2:0] btn, //set, inc sec, inc min
    output [3:0] com,
    output [7:0] seg_7
    );

    wire btn_0_p, btn_1_p, btn_2_p;

    //setmode 설정 TFF
    //setmode : 1 setmode 진입, 0 runmode
    T_flip_flop_p TFF_setmode (clk, reset_p, btn_0_p, setmode);

    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire inc_sec;
    wire inc_min;
    assign inc_sec = setmode ? btn_1_p : clk_sec; //setmode진입시 버튼입력 MUX
    assign inc_min = setmode ? btn_2_p : clk_min; //setmode진입시 버튼입력 MUX

    //버튼입력 감지, 디바운싱, 엣지검출 1펄스 출력
    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_0_p); // pause
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_1_p); // inc sec
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_2_p); // inc min

    //1us, 1ms, 1s, 1m 타이머
    clock_usec     clk_us (clk, reset_p, clk_usec);           // sysclk -> 1us
    clock_div_1000 clk_ms (clk, reset_p, clk_usec, clk_msec); // 1us -> 1ms
    clock_div_1000 clk_s  (clk, reset_p, clk_msec, clk_sec);  // 1ms -> 1s
    clock_min      clk_m  (clk, reset_p, inc_sec,  clk_min);  // 1s -> 1m

    //FND 데이터 가공 60진카운터
    wire [3:0] sec_1, sec_10, min_1, min_10;
    counter_dec_60 cnt_sec (clk, reset_p, inc_sec, sec_1, sec_10);
    counter_dec_60 cnt_min (clk, reset_p, inc_min, min_1, min_10); 

    
    wire [3:0] com_normal;    
    fnd_4_digit_cntr fnd(.clk(clk), 
                         .reset_p(reset_p), 
                         .value({min_10, min_1, sec_10, sec_1}),
                         .segment_data_ca(seg_7), 
                         .com_sel(com_normal));

    clk_1sec blinker_1s (clk, reset_p, clk_msec, blink_1s);
    assign com = (setmode&blink_1s) ? 4'b1111 : com_normal;
endmodule


module loadable_watch_top (
    input clk, reset_p,
    input [2:0] btn, //set, inc sec, inc min
    output [3:0] com,
    output [7:0] seg_7
    );

    wire btn_0_p, btn_1_p, btn_2_p;

    //setmode 설정 TFF
    //setmode : 1 setmode 진입, 0 runmode
    T_flip_flop_p TFF_setmode (clk, reset_p, btn_0_p, setmode);

    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire inc_sec;
    assign inc_sec = setmode ? btn_1_p : clk_sec; //setmode진입시 버튼입력 MUX

    //버튼입력 감지, 디바운싱, 엣지검출 1펄스 출력
    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_0_p); // pause
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_1_p); // inc sec
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_2_p); // inc min

    //1us, 1ms, 1s, 1m 타이머
    clock_usec     clk_us (clk, reset_p, clk_usec);           // sysclk -> 1us
    clock_div_1000 clk_ms (clk, reset_p, clk_usec, clk_msec); // 1us -> 1ms
    clock_div_1000 clk_s  (clk, reset_p, clk_msec, clk_sec);  // 1ms -> 1s
    clock_min      clk_m  (clk, reset_p, inc_sec,  clk_min);  // 1s -> 1m



    //setmode 엣지 검출
    wire cur_time_load_en, set_time_load_en;
    edge_detector_p ed_setmode (clk, reset_p, setmode, set_time_load_en, cur_time_load_en);

    //FND 데이터 가공 60진카운터
    //로더블 카운터 와이어링
    wire [3:0] cur_sec_1, cur_sec_10, set_sec_1, set_sec_10;
    wire [3:0] cur_min_1, cur_min_0, set_min_1, set_min_10;
    loadable_counter_dec_60 cur_time_sec(clk,
                                         reset_p, 
                                         clk_sec, 
                                         cur_time_load_en, 
                                         set_sec_1, 
                                         set_sec_10, 
                                         cur_sec_1, 
                                         cur_sec_10);
    loadable_counter_dec_60 cur_time_min(clk,
                                         reset_p, 
                                         clk_min, 
                                         cur_time_load_en, 
                                         set_min_1, 
                                         set_min_10, 
                                         cur_min_1, 
                                         cur_min_10);    

    loadable_counter_dec_60 set_time_sec(clk,
                                         reset_p, 
                                         btn_1_p, 
                                         set_time_load_en, 
                                         cur_sec_1, 
                                         cur_sec_10, 
                                         set_sec_1, 
                                         set_sec_10);
    loadable_counter_dec_60 set_time_min(clk,
                                         reset_p, 
                                         btn_2_p, 
                                         set_time_load_en, 
                                         cur_min_1, 
                                         cur_min_10, 
                                         set_min_1, 
                                         set_min_10);       
    //FND 출력데이터 선택
    wire [3:0] com_normal;    
    wire [15:0] time_digit;
    // setmode일때 세팅중인 값 출력, run모드일때 현재시간 출력
    assign time_digit = setmode ? {set_min_10,set_min_1,set_sec_10,set_sec_1} :
                                  {cur_min_10,cur_min_1,cur_sec_10,cur_sec_1};
    fnd_4_digit_cntr fnd(.clk(clk), 
                         .reset_p(reset_p), 
                         .value(time_digit),
                         .segment_data_ca(seg_7), 
                         .com_sel(com_normal));

    //setmode 진입시 1초주기 blink
    wire blink_1s;
    clk_1sec blinker_1s (clk, reset_p, clk_msec, blink_1s);
    assign com = (setmode&blink_1s) ? 4'b1111 : com_normal;
endmodule


module loadable_watch_top_cn (
    input clk, reset_p,
    input [3:0] btn, //set, inc sec, inc min , cancel
    output [3:0] com,
    output [7:0] seg_7
    );

    wire btn_0_p, btn_1_p, btn_2_p, btn_3_p;
    wire cur_time_load_en_1;

    wire setmode;
    wire clk_usec, clk_msec, clk_sec, clk_min, inc_sec;
    wire btn_1_p_set;

    //setmode 엣지 검출
    wire cur_time_load_en, set_time_load_en;
    edge_detector_n ed_setmode (clk, reset_p, setmode, set_time_load_en, cur_time_load_en);

    //setmode 시간 동기화
    assign btn_1_p_set = setmode ? btn_1_p : 1'b0;
    assign inc_sec = clk_sec | btn_1_p_set;          

    wire clear;
    or (clear, reset_p, btn_3_p);
    T_flip_flop_p TFF_setmode (clk, clear, btn_0_p, setmode);

    assign cur_time_load_en_1 = btn[3] ? 1'b0 : cur_time_load_en;
    // bufif0(cur_time_load_en, cur_time_load_en_1, btn_3_p);

    //버튼입력 감지, 디바운싱, 엣지검출 1펄스 출력
    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_0_p); // pause
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_1_p); // inc sec
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_2_p); // inc min
    button_cntr btn_cntr_3 (clk, reset_p, btn[3], btn_3_p); // cancel

    //1us, 1ms, 1s, 1m 타이머
    clock_usec     clk_us (clk, reset_p, clk_usec);           // sysclk -> 1us
    clock_div_1000 clk_ms (clk, reset_p, clk_usec, clk_msec); // 1us -> 1ms
    clock_div_1000 clk_s  (clk, reset_p, clk_msec, clk_sec);  // 1ms -> 1s
    clock_min      clk_m  (clk, reset_p, inc_sec,  clk_min);  // 1s -> 1m

    //FND 데이터 가공 60진카운터
    //로더블 카운터 와이어링
    wire [3:0] cur_sec_1, cur_sec_10, set_sec_1, set_sec_10;
    wire [3:0] cur_min_1, cur_min_0, set_min_1, set_min_10;
    loadable_counter_dec_60 cur_time_sec(clk,
                                         reset_p, 
                                         clk_sec, 
                                         cur_time_load_en_1, 
                                         set_sec_1, 
                                         set_sec_10, 
                                         cur_sec_1, 
                                         cur_sec_10);
    loadable_counter_dec_60 cur_time_min(clk,
                                         reset_p, 
                                         clk_min, 
                                         cur_time_load_en_1, 
                                         set_min_1, 
                                         set_min_10, 
                                         cur_min_1, 
                                         cur_min_10);    

    loadable_counter_dec_60 set_time_sec(clk,
                                         reset_p, 
                                         btn_1_p, 
                                         set_time_load_en, 
                                         cur_sec_1, 
                                         cur_sec_10, 
                                         set_sec_1, 
                                         set_sec_10);
    loadable_counter_dec_60 set_time_min(clk,
                                         reset_p, 
                                         btn_2_p, 
                                         set_time_load_en, 
                                         cur_min_1, 
                                         cur_min_10, 
                                         set_min_1, 
                                         set_min_10);       
    //FND 출력데이터 선택
    wire [3:0] com_normal;    
    wire [15:0] time_digit;
    // setmode일때 세팅중인 값 출력, run모드일때 현재시간 출력
    assign time_digit = setmode ? {set_min_10,set_min_1,set_sec_10,set_sec_1} :
                                  {cur_min_10,cur_min_1,cur_sec_10,cur_sec_1};
    fnd_4_digit_cntr fnd(.clk(clk), 
                         .reset_p(reset_p), 
                         .value(time_digit),
                         .segment_data_ca(seg_7), 
                         .com_sel(com_normal));

    //setmode 진입시 1초주기 blink
    wire blink_1s;
    clk_1sec blinker_1s (clk, reset_p, clk_msec, blink_1s);
    assign com = (setmode&blink_1s) ? 4'b1111 : com_normal;
endmodule



module stop_watch_top(
    input clk, reset_p,
    input [3:0]btn,
    output [3:0] com,
    output [7:0] seg_7
    );
    wire btn_0_p, btn_1_p, btn_2_p, btn_3_p;
    wire start_stop;
    wire clk_out;
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire [3:0] sec_1, sec_10, min_1, min_10;

    wire reset, restart;
    wire lap_swatch, lap_load_p, lap_load_n;
    wire lap_load_pn;
    assign reset = reset_p | restart;

    assign restart = (~start_stop) & lap_load_pn;
    assign lap_load_pn = lap_load_n | lap_load_p;
    
    //start_stop : 1 start, 0 stop
    assign clk_out = start_stop ? clk : 1'b0;
    T_flip_flop_p TFF_setmode (clk, reset, btn_0_p, start_stop);
    T_flip_flop_p TFF_lap (clk, reset, btn_1_p, lap_swatch);

    edge_detector_n ed_lap (clk, reset, lap_swatch, lap_load_p, lap_load_n);



    //저장 레지스터 
    reg [15:0] lap;
    always @(posedge clk, posedge reset) begin
        if (reset) lap = 0;
        else if (lap_load_p) lap = {min_10, min_1, sec_10, sec_1};
    end

    //fnd 데이터 선택 mux
    wire [15:0] value;
    assign value = lap_swatch ? lap : {min_10, min_1, sec_10, sec_1};

    button_cntr btn_cntr_0 (clk, reset, btn[0], btn_0_p); // 
    button_cntr btn_cntr_1 (clk, reset, btn[1], btn_1_p); // 
    button_cntr btn_cntr_2 (clk, reset, btn[2], btn_2_p); // 
    button_cntr btn_cntr_3 (clk, reset, btn[3], btn_3_p); // 
    
    //1us, 1ms, 1s, 1m 타이머
    clock_usec     clk_us (clk_out, reset, clk_usec);           // sysclk -> 1us
    clock_div_1000 clk_ms (clk_out, reset, clk_usec, clk_msec); // 1us -> 1ms
    clock_div_1000 clk_s  (clk_out, reset, clk_msec, clk_sec);  // 1ms -> 1s
    clock_min      clk_m  (clk_out, reset, clk_sec,  clk_min);  // 1s -> 1m

    counter_dec_60 sec(clk, reset, clk_sec, sec_1, sec_10);
    counter_dec_60 min(clk, reset, clk_min, min_1, min_10);

    //FND 출력    
    fnd_4_digit_cntr fnd(.clk(clk), 
                         .reset_p(reset), 
                         .value(value),
                         .segment_data_ca(seg_7), 
                         .com_sel(com));
                         
endmodule

module stop_watch_top_ms(
    input clk, reset_p,
    input [1:0]btn,
    output [3:0] com,
    output [7:0] seg_7
    );
    
    wire btn_0_p, btn_1_p;
    wire start_stop;
    wire clk_out;
    wire clk_usec, clk_msec, clk_sec;
    wire [3:0] msec_10, msec_100, sec_1, sec_10;

    wire reset, restart;
    wire lap_swatch, lap_load_p;
    wire lap_load_pn;
    wire [15:0] value;
    wire [7:0] seg_7_normal;

    reg [15:0] lap;
    always @(posedge clk, posedge reset) begin
        if (reset) lap = 0;
        else if (lap_load_p) lap = {sec_10, sec_1, msec_10, msec_100};
    end

    assign value   = lap_swatch ? lap : {sec_10, sec_1, msec_100, msec_10};
    assign reset   = reset_p | restart;
    assign clk_out = start_stop ? clk : 1'b0;
    assign restart = (~start_stop) & lap_load_p;
    assign seg_7   = (com == 4'b1011) ? seg_7_normal | 8'b0000_0001 : seg_7_normal;
       
    T_flip_flop_p TFF_setmode (clk, reset, btn_0_p, start_stop);
    T_flip_flop_p     TFF_lap (clk, reset, btn_1_p, lap_swatch);

    edge_detector_n    ed_lap (clk, reset, lap_swatch, lap_load_p);

    button_cntr    btn_cntr_0 (clk, reset, btn[0], btn_0_p); // 
    button_cntr    btn_cntr_1 (clk, reset, btn[1], btn_1_p); // 
    
    clock_usec         clk_us (clk_out, reset, clk_usec);           // sysclk -> 1us
    clock_div_1000     clk_ms (clk_out, reset, clk_usec, clk_msec); // 1us -> 1ms
    clock_div_1000     clk_s  (clk_out, reset, clk_msec, clk_sec);  // 1ms -> 1s

    counter_dec_100      msec (clk, reset, clk_msec, msec_1, msec_10);
    counter_dec_100      sec  (clk, reset, clk_sec, sec_1, sec_10);

    fnd_4_digit_cntr      fnd (.clk(clk), 
                               .reset_p(reset_p), 
                               .value(value),
                               .segment_data_ca(seg_7_normal), 
                               .com_sel(com));
endmodule




module cook_timer_0 (
    input clk, reset_p,
    input [3:0] btn,  //0 start/pause, 1 set_sec, 0 set_min, 3 reset
    output [3:0] com,
    output [7:0] seg_7,
    output led,
    output buz_clk );

    wire clk_usec, clk_msec, clk_sec;
    wire run;
    wire btn_run_p, btn_inc_tgt_sec_p, btn_inc_tgt_min_p, btn_restart_p;
    wire clk_under_flow_sec_1, clk_under_flow_sec_10, clk_under_flow_min_1;
    wire [3:0] sec_1, sec_10, min_1, min_10;
    wire [15:0] value;

    assign reset = reset_p | btn_restart_p;
    assign clk_run = (run & ~led) ? clk : 1'b0;
    assign btn_inc_tgt_sec_p = run ? 1'b0 : btn_inc_tgt_sec_p_o;
    assign btn_inc_tgt_min_p = run ? 1'b0 : btn_inc_tgt_min_p_o;
    assign value = {min_10, min_1, sec_10, sec_1};
    assign led = (run & (min_10|min_1|sec_10|sec_1) == 0) ? 1'b1 : 1'b0;
    
    reg [16:0] clk_div;
    always @ (posedge clk) clk_div = clk_div + 1;
    assign buz_clk = led ? clk_div[12] : 1'b0;  //12 : 15.26khz

    T_flip_flop_p TFF_run (clk, reset, btn_run_p, run);

    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_run_p); // 
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_inc_tgt_sec_p_o); // 
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_inc_tgt_min_p_o); // 
    button_cntr btn_cntr_3 (clk, reset_p, btn[3], btn_restart_p); // 

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
    
    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset), 
                               .value           (value),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );
endmodule



module functional_watch (
    input clk, reset_p,
    input [3:0] btn,
    input btn_mode,
    output [3:0] com,
    output [7:0] seg_7,
    output led,
    output buz_clk    );

    parameter watch_mode  = 0;
    parameter swatch_mode = 1;
    parameter timer_mode  = 2;

    wire btn_mode_p;
    button_cntr btn_mode_cntr (clk, reset_p, btn_mode, btn_mode_p);

    reg [1:0] mode; // 0 ~ 2
    always @(posedge clk, posedge reset_p)begin
        if (reset_p) mode = 0;
        else if (btn_mode_p) begin
            if (mode >= 2) mode = 0;
            else mode = mode + 1;         
        end
    end

    wire [3:0] btn_watch, btn_swatch, btn_ct;
    wire [3:0] com_watch, com_swatch, com_ct;
    wire [7:0] seg_7_watch, seg_7_swatch, seg_7_ct;

    // assign btn_watch  = (mode == watch_mode)  ? btn : 4'b0000;
    // assign btn_swatch = (mode == swatch_mode) ? btn : 4'b0000;
    // assign btn_ct     = (mode == timer_mode)  ? btn : 4'b0000;

    assign {btn_watch, btn_swatch, btn_ct} = (mode == watch_mode)  ? {btn[3:0], 4'b0000, 4'b0000} :
                                             (mode == swatch_mode) ? {4'b0000, btn[3:0], 4'b0000} :
                                             (mode == timer_mode)  ? {4'b0000, 4'b0000, btn[3:0]} : 
                                             /* default */            12'b0000;

    assign com        = (mode == watch_mode)  ? com_watch :
                        (mode == swatch_mode) ? com_swatch :
                        (mode == timer_mode)  ? com_ct : 4'b1111;
    
    assign seg_7      = (mode == watch_mode)  ? seg_7_watch :
                        (mode == swatch_mode) ? seg_7_swatch :
                        (mode == timer_mode)  ? seg_7_ct : 8'b0000_0000;

    
    loadable_watch_top_cn  watch (.clk     (clk),
                                  .reset_p (reset_p),
                                  .btn     (btn_watch),
                                  .com     (com_watch),
                                  .seg_7   (seg_7_watch) );
        
    stop_watch_top_ms stop_watch (.clk     (clk),
                                  .reset_p (reset_p),
                                  .btn     (btn_swatch),
                                  .com     (com_swatch),
                                  .seg_7   (seg_7_swatch) );

    cook_timer_0      cook_timer (.clk     (clk),
                                  .reset_p (reset_p),
                                  .btn     (btn_ct),
                                  .com     (com_ct),
                                  .seg_7   (seg_7_ct),
                                  .led     (led),
                                  .buz_clk (buz_clk) );
endmodule


module loadable_watch_core (
    input clk, reset_p,
    input [3:0] btn_edge, 
    // btn_edge[0] : set,     btn_edge[1] : inc sec, 
    // btn_edge[2] : inc min, btn_edge[3] : cancel
    output [15:0] time_digit
    );
    wire clk_usec, clk_msec, clk_sec, clk_10_sec, clk_min, clk_10_min;
    wire [3:0] tgt_min_10, tgt_min_1, tgt_sec_10, tgt_sec_1;
    wire [3:0] min_10, min_1, sec_10, sec_1;
    
    wire setmode, setmode_p, setmode_n;
    wire btn_inc_sec, btn_inc_min, btn_cancel;
    assign btn_inc_sec = setmode ? btn_edge[1] : 0;
    assign btn_inc_min = setmode ? btn_edge[2] : 0;
    assign btn_cancel  = setmode ? btn_edge[3] : 0;

    T_flip_flop_p TFF_setmode (clk, reset, btn_edge[0], setmode);
    edge_detector_p ed_setmode (clk, reset_p, setmode, setmode_p, setmode_n);
    
    clock_usec #(125) clk_us (clk, reset_p, clk_usec);
    clock_div_1000 clk_ms (clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 clk_s  (clk, reset_p, clk_msec, clk_sec);

    //target time counter
    load_count_ud_N #(10) sec_1_t (.clk          (clk),
                                   .reset_p      (reset_p),
                                   .clk_up       (btn_inc_sec),
                                   .data_load    (setmode_p),
                                   .set_value    (sec_1),
                                   .digit        (tgt_sec_1),
                                   .clk_over_flow(clk_10_sec_t) );

    load_count_ud_N #(6) sec_10_t (.clk          (clk),
                                   .reset_p      (reset_p),
                                   .clk_up       (clk_10_sec_t),
                                   .data_load    (setmode_p),
                                   .set_value    (sec_10),
                                   .digit        (tgt_sec_10) );

    load_count_ud_N #(10) min_1_t (.clk          (clk),
                                   .reset_p      (reset_p),
                                   .clk_up       (btn_inc_min),
                                   .data_load    (setmode_p),
                                   .set_value    (min_1),
                                   .digit        (tgt_min_1),
                                   .clk_over_flow(clk_10_min_t) );                                                         

    load_count_ud_N #(10) min_10_t(.clk          (clk),
                                   .reset_p      (reset_p),
                                   .clk_up       (clk_10_min_t),
                                   .data_load    (setmode_p),
                                   .set_value    (min_10),
                                   .digit        (tgt_min_10) );

    // run time counter
    load_count_ud_N #(10) sec_1_ (.clk           (clk),
                                  .reset_p       (reset_p),
                                  .clk_up        (clk_sec),
                                  .data_load     (setmode_n),
                                  .set_value     (tgt_sec_1),
                                  .digit         (sec_1),
                                  .clk_over_flow (clk_10_sec) );

    load_count_ud_N #(6) sec_10_ (.clk           (clk),
                                  .reset_p       (reset_p),
                                  .clk_up        (clk_10_sec),
                                  .data_load     (setmode_n),
                                  .set_value     (tgt_sec_10),
                                  .digit         (sec_10),
                                  .clk_over_flow (clk_min) );    

    load_count_ud_N #(10) min_1_ (.clk           (clk),
                                  .reset_p       (reset_p),
                                  .clk_up        (clk_min),
                                  .data_load     (setmode_n),
                                  .set_value     (tgt_min_1),
                                  .digit         (min_1),
                                  .clk_over_flow (clk_10_min) );                                                         

    load_count_ud_N #(10) min_10_(.clk           (clk),
                                  .reset_p       (reset_p),
                                  .clk_up        (clk_10_min),
                                  .data_load     (setmode_n),
                                  .set_value     (tgt_min_10),
                                  .digit         (min_10) );

    assign time_digit = setmode ? {tgt_min_10, tgt_min_1, tgt_sec_10, tgt_sec_1} : 
                                  {min_10, min_1, sec_10, sec_1};
endmodule


module stop_watch_core (
    input clk, reset_p,
    input [3:0] btn_edge,
    output [15:0] time_digit
    );


    assign reset   = reset_p | restart;
    assign clk_out = start_stop ? clk : 1'b0;
    wire lap_swatch, lap_load_p;
    assign restart = (~start_stop) & lap_load_p;
    wire [3:0] sec_10, sec_1, msec_100, msec_10;
    wire clk_100_msec, clk_10_msec;
    wire clk_usec, clk_msec, clk_sec;

    T_flip_flop_p TFF_setmode (clk, reset, btn_edge[0], start_stop);
    T_flip_flop_p     TFF_lap (clk, reset, btn_edge[1], lap_swatch);
    edge_detector_n    ed_lap (clk, reset, lap_swatch, lap_load_p);
    
    clock_usec         clk_us (clk_out, reset, clk_usec);           // sysclk -> 1us
    clock_div_1000     clk_ms (clk_out, reset, clk_usec, clk_msec); // 1us -> 1ms
    // clock_div_1000     clk_s  (clk_out, reset, clk_msec, clk_sec);  // 1ms -> 1s

    load_count_ud_N #(10) msec_1_ (.clk           (clk),
                                   .reset_p       (reset),
                                   .clk_up        (clk_msec),
                                   .clk_over_flow (clk_10_msec) );

    load_count_ud_N #(10) msec_10_(.clk           (clk),
                                   .reset_p       (reset),
                                   .clk_up        (clk_10_msec),
                                   .digit         (msec_10),
                                   .clk_over_flow (clk_100_msec) );
                                  
    load_count_ud_N #(10) msec_100_(.clk          (clk),
                                   .reset_p       (reset),
                                   .clk_up        (clk_100_msec),
                                   .digit         (msec_100),
                                   .clk_over_flow (clk_sec) );
                                  
    load_count_ud_N #(10) sec_1_  (.clk           (clk),
                                   .reset_p       (reset),
                                   .clk_up        (clk_sec),
                                   .digit         (sec_1),
                                   .clk_over_flow (clk_10_sec) );

    load_count_ud_N #(10) sec_10_ (.clk           (clk),
                                   .reset_p       (reset),
                                   .clk_up        (clk_10_sec),
                                   .digit         (sec_10) );
    
    reg [15:0] lap;
    always @(posedge clk, posedge reset) begin
        if (reset) lap = 0;
        else if (lap_load_p) lap = {sec_10, sec_1, msec_100, msec_10};
    end
    assign time_digit = lap_swatch ? lap : {sec_10, sec_1, msec_100, msec_10};

endmodule


module cook_timer_core (
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


module watch_top_0403 (
    input clk, reset_p,
    input [3:0] btn, //set, inc sec, inc min
    input btn_mode,
    output [3:0] com,
    output [7:0] seg_7,
    output led,
    output buz_clk  );

    parameter watch_mode  = 0;
    parameter swatch_mode = 1;
    parameter timer_mode  = 2;

    wire [3:0] btn_p;
    wire btn_0_p, btn_1_p, btn_2_p, btn_3_p;
    assign btn_p = {btn_3_p, btn_2_p, btn_1_p, btn_0_p}; 
    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_0_p);
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_1_p);
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_2_p);
    button_cntr btn_cntr_3 (clk, reset_p, btn[3], btn_3_p);
    button_cntr btn_cntr_mode (clk, reset_p, btn_mode, btn_mode_p);

    reg [1:0] mode; // 0 ~ 2
    always @(posedge clk, posedge reset_p)begin
        if (reset_p) mode = 0;
        else if (btn_mode_p) begin
            if (mode >= 2) mode = 0;
            else mode = mode + 1;         
        end
    end

    wire [3:0] btn_p_watch, btn_p_swatch, btn_p_timer;
    wire [15:0] time_digit_watch, time_digit_swatch, time_digit_timer;
    wire [15:0] time_digit;
    
    loadable_watch_core  watch_0 (.clk        (clk),
                                  .reset_p    (reset_p),
                                  .btn_edge   (btn_p_watch),
                                  .time_digit (time_digit_watch) );

    stop_watch_core stop_watch_0 (.clk        (clk),
                                  .reset_p    (reset_p),
                                  .btn_edge   (btn_p_swatch),
                                  .time_digit (time_digit_swatch) );
            
    cook_timer_core cook_timer_0 (.clk        (clk),
                                  .reset_p    (reset_p),
                                  .btn_edge   (btn_p_timer),
                                  .time_digit (time_digit_timer),
                                  .led        (led),
                                  .buz_clk    (buz_clk) );

    assign btn_p_watch  = (mode == watch_mode)  ? {btn_3_p, btn_2_p, btn_1_p, btn_0_p} : 4'b0000;
    assign btn_p_swatch = (mode == swatch_mode) ? {btn_3_p, btn_2_p, btn_1_p, btn_0_p} : 4'b0000;
    assign btn_p_timer  = (mode == timer_mode)  ? {btn_3_p, btn_2_p, btn_1_p, btn_0_p} : 4'b0000;

    assign time_digit   = (mode == watch_mode)  ? time_digit_watch  :
                          (mode == swatch_mode) ? time_digit_swatch :
                          (mode == timer_mode)  ? time_digit_timer  : 16'b0000_0000;

    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset_p), 
                               .value           (time_digit),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );
endmodule

module led_pwm_top #(
    parameter SYS_FREQ = 125
) (
    input clk, reset_p,
    output pwm_r, pwm_g, pwm_b, pwm_o
);
    reg[27:0] clk_div;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
           clk_div <= 0; 
        end
        else begin
            clk_div <= clk_div + 1;
        end
    end

    pwm_controller #(SYS_FREQ) pwmr(.clk      (clk), 
                                    .reset_p  (reset_p), 
                                    .duty     (clk_div[27:21]),
                                    .pwm_freq (10000), 
                                    .pwm      (pwm_r)          );

    pwm_controller #(SYS_FREQ) pwmg(.clk      (clk), 
                                    .reset_p  (reset_p), 
                                    .duty     (clk_div[26:20]),
                                    .pwm_freq (10000), 
                                    .pwm      (pwm_g)          );

    pwm_controller #(SYS_FREQ) pwmb(.clk      (clk), 
                                    .reset_p  (reset_p), 
                                    .duty     (clk_div[25:19]),
                                    .pwm_freq (10000), 
                                    .pwm      (pwm_b)          );

    pwm_controller #(SYS_FREQ) pwmo(.clk      (clk), 
                                    .reset_p  (reset_p), 
                                    .duty     (95),
                                    .pwm_freq (25), 
                                    .pwm      (pwm_o)          );

 
endmodule



module dc_motor_pwm_top #(
    parameter SYS_FREQ = 125,
    parameter N = 10
) (
    input clk, reset_p,
    output motor_pwm );
    
    reg[29:0] clk_div;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) clk_div <= 0; 
        else clk_div <= clk_div + 1;
    end

    pwm_controller #(SYS_FREQ, N) pwm_motor(.clk      (clk), 
                                         .reset_p  (reset_p), 
                                         .duty     (1023),
                                         .pwm_freq (60), 
                                         .pwm      (motor_pwm)          );

endmodule

module fan_test #(
    parameter SYS_FREQ = 125
) (
    input clk, reset_p,
    input [3:0] btn,
    output reg [1:0] dir,
    output motor_pwm );
    
    btn_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_0_p);
    btn_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_1_p);
    btn_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_2_p);
    btn_cntr btn_cntr_3 (clk, reset_p, btn[3], btn_3_p);

    reg [6:0] pwm_duty;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin 
            pwm_duty <= 0;
            dir <= 2'b01;
        end
        else begin
            if (btn_0_p) pwm_duty <= pwm_duty + 1;
            else if (btn_1_p) pwm_duty <= pwm_duty - 1;
            else if (btn_2_p) pwm_duty <= 0;
            else if (btn_3_p) begin
                dir <= 2'b10;
            end
        end
    end 

    pwm_controller #(SYS_FREQ) pwm_motor(.clk      (clk), 
                                         .reset_p  (reset_p), 
                                         .duty     (pwm_duty),
                                         .pwm_freq (60), 
                                         .pwm      (motor_pwm)          );

endmodule

module sg90_test_top #(
    parameter SYS_FREQ = 125,
    parameter N = 12
) (
    input clk, reset_p,
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output motor_pwm );

    // 0.5ms =  2.5% duty  -> right
    //   1ms =    5% duty  
    // 1.5ms =  7.5% duty  -> center
    //   2ms =   10% duty
    // 2.5ms = 12.5% duty  -> left

    // N=10 기준
    // 1024 * 0.025 =  26    (25.6)
    // 1024 * 0.05  =  51    (51.2)
    // 1024 * 0.075 =  77    (76.8)
    // 1024 * 0.1   = 102   (102.4)
    // 1024 * 0.125 = 128

    // N=12 기준
    localparam offset = 9;  // 높아질수록 왼쪽으로 이동
    // 이론적인 값
    localparam deg_0_t   =  512; //left
    localparam deg_90_t  =  308; //center
    localparam deg_180_t =  104; //right
    // offset 적용한 값
    localparam deg_0_a   = deg_0_t   + offset; //left
    localparam deg_90_a  = deg_90_t  + offset; //center
    localparam deg_180_a = deg_180_t + offset; //right
    // 1도당 필요 값
    // deg_0_t - deg_180_t = 408
    // 408/180 = 2.2666
    // localparam deg_1 = (deg_0_t - deg_180_t) / 180;  // 408/180 = 2.2666


    wire [3:0]btn_p;
    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_p[0]);
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_p[1]);
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_p[2]);
    button_cntr btn_cntr_3 (clk, reset_p, btn[3], btn_p[3]);

    wire clk_usec, clk_msec, clk_Nmsec;
    clock_usec #(SYS_FREQ) usec(clk, reset_p, clk_usec);
    clock_div_1000 msec(clk, reset_p, clk_usec, clk_msec);
    clock_div_N #(4) Nmsec(clk, reset_p, clk_msec, clk_Nmsec);

    reg [N-1:0] pwm_duty;
    reg dir_toggle;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin 
            pwm_duty <= deg_90_a;
            dir_toggle <= 1'b1; // 왼쪽 먼저
        end
        else begin
            if (btn_p[0]) begin // 누를때마다 방향전환
                dir_toggle = ~dir_toggle;
            end
            else if (btn_p[1]) begin // 오른쪽 끝으로
                pwm_duty = deg_180_a;
            end
            else if (btn_p[2]) begin // 가운데로
                pwm_duty = deg_90_a;
            end
            else if (btn_p[3]) begin // 왼쪽 끝으로
                pwm_duty = deg_0_a;
            end
            else begin
                if (clk_Nmsec) begin //toggle 1이면 왼쪽 0이면 오른쪽
                    pwm_duty = ( dir_toggle ? pwm_duty + 1 : pwm_duty - 1 );
                    if (pwm_duty <= deg_180_a) dir_toggle = ~dir_toggle;
                    else if (pwm_duty >= deg_0_a) dir_toggle = ~dir_toggle;
                end
            end
            // case (btn_p)
            //     4'b0001 : begin 
            //         pwm_duty = pwm_duty - 23; // 대충 10도씩 움직임
            //         if (pwm_duty < deg_180_a) pwm_duty = deg_180_a; // Right
            //     end
            //     4'b0010 : begin
            //         pwm_duty = pwm_duty + 23;
            //         if (pwm_duty > deg_0_a) pwm_duty = deg_0_a;     //Left
            //     end
            //     4'b0100 : pwm_duty = deg_180_a;             // Right max
            //     4'b1000 : pwm_duty = deg_0_a;               // Left max
            //     default : pwm_duty = pwm_duty;               // 전 상태 유지
            // endcase

        end
    end

    pwm_controller #(SYS_FREQ, N) pwm_motor(.clk      (clk), 
                                            .reset_p  (reset_p), 
                                            .duty     (pwm_duty),
                                            .pwm_freq (50), 
                                            .pwm      (motor_pwm)          );


    wire [15:0] pwm_data;
    bin_to_dec btd(.bin({pwm_duty}), .bcd(pwm_data));

    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset_p), 
                               .value           (pwm_data),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );
endmodule


module sg90_test_top_prd #(
    parameter SYS_FREQ = 125
) (
    input clk, reset_p,
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output motor_pwm );

    // 0.5ms =  2.5% duty  -> right
    //   1ms =    5% duty  
    // 1.5ms =  7.5% duty  -> center
    //   2ms =   10% duty
    // 2.5ms = 12.5% duty  -> left

    // N=10 기준
    // 1024 * 0.025 =  26    (25.6)
    // 1024 * 0.05  =  51    (51.2)
    // 1024 * 0.075 =  77    (76.8)
    // 1024 * 0.1   = 102   (102.4)
    // 1024 * 0.125 = 128

    // N=12 기준
    localparam offset = 0;  // 높아질수록 왼쪽으로 이동
    // 이론적인 값
    localparam deg_0_t   =  312500; //left
    localparam deg_90_t  =  187500; //center
    localparam deg_180_t =  62500; //right
    // offset 적용한 값
    localparam deg_0_a   = deg_0_t   + offset; //left
    localparam deg_90_a  = deg_90_t  + offset; //center
    localparam deg_180_a = deg_180_t + offset; //right
    // 1도당 필요 값
    // deg_0_t - deg_180_t = 408
    // 408/180 = 2.2666
    // localparam deg_1 = (deg_0_t - deg_180_t) / 180;  // 408/180 = 2.2666


    wire [3:0]btn_p;
    button_cntr btn_cntr_0 (clk, reset_p, btn[0], btn_p[0]);
    button_cntr btn_cntr_1 (clk, reset_p, btn[1], btn_p[1]);
    button_cntr btn_cntr_2 (clk, reset_p, btn[2], btn_p[2]);
    button_cntr btn_cntr_3 (clk, reset_p, btn[3], btn_p[3]);

    wire clk_usec, clk_msec, clk_Nmsec;
    clock_usec #(SYS_FREQ) usec(clk, reset_p, clk_usec);
    clock_div_1000 msec(clk, reset_p, clk_usec, clk_msec);
    clock_div_N #(5) Nmsec(clk, reset_p, clk_msec, clk_Nmsec);

    reg [26:0] pwm_duty;
    reg dir_toggle;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin 
            pwm_duty <= deg_90_a;
            dir_toggle <= 1'b1; // 왼쪽 먼저
        end
        else begin
            if (btn_p[0]) begin // 누를때마다 방향전환
                dir_toggle = ~dir_toggle;
            end
            else if (btn_p[1]) begin // 오른쪽 끝으로
                pwm_duty = deg_180_a;
            end
            else if (btn_p[2]) begin // 가운데로
                pwm_duty = deg_90_a;
            end
            else if (btn_p[3]) begin // 왼쪽 끝으로
                pwm_duty = deg_0_a;
            end
            else begin
                if (clk_Nmsec) begin //toggle 1이면 왼쪽 0이면 오른쪽
                    pwm_duty = ( dir_toggle ? pwm_duty + 200 : pwm_duty - 200 );
                    if (pwm_duty <= deg_180_a) dir_toggle = ~dir_toggle;
                    else if (pwm_duty >= deg_0_a) dir_toggle = ~dir_toggle;
                end
            end
            // case (btn_p)
            //     4'b0001 : begin 
            //         pwm_duty = pwm_duty - 23; // 대충 10도씩 움직임
            //         if (pwm_duty < deg_180_a) pwm_duty = deg_180_a; // Right
            //     end
            //     4'b0010 : begin
            //         pwm_duty = pwm_duty + 23;
            //         if (pwm_duty > deg_0_a) pwm_duty = deg_0_a;     //Left
            //     end
            //     4'b0100 : pwm_duty = deg_180_a;             // Right max
            //     4'b1000 : pwm_duty = deg_0_a;               // Left max
            //     default : pwm_duty = pwm_duty;               // 전 상태 유지
            // endcase

        end
    end


    pwm_controller_period pwm_motor_p(.clk(clk),
                                      .reset_p(reset_p),
                                      .duty(pwm_duty),
                                      .pwm_period(2500000),
                                      .pwm(motor_pwm) );

    wire [15:0] pwm_data;
    bin_to_dec btd(.bin(pwm_duty), .bcd(pwm_data));

    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset_p), 
                               .value           (pwm_data),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );
endmodule

module adc_top(
    input clk, reset_p,
    input vauxn6, vauxp6,
    output [3:0] com,
    output [7:0] seg_7,
    output motor_pwm    );

    // ADC 모듈 와이어링
    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out; 

    // ADC 모듈 인스턴스
    xadc_wiz_0 adc_2(
          .daddr_in({2'b00, channel_out}),
          .dclk_in(clk),
          .den_in(eoc_out),
        //   .di_in;
        //   .dwe_in;
          .reset_in(reset_p),
          .vauxp6(vauxp6),
          .vauxn6(vauxn6),

        //   .busy_out; // 데이터 변환이 진행중인 상태
          .channel_out(channel_out),
          .do_out(do_out),  //12비트 ADC, 상위비트부터 채움
        //   .drdy_out;
          .eoc_out(eoc_out)  // End of Conversion
        //   .eos_out;  // End of Sequence 싱글채널모드에선 사용안함. ADC가 3개면 3개 모두 스캔 되어야 EOS가 발생
        //   .alarm_out;   
        //   .vp_in;
        //   .vn_in;
    );

    wire eoc_out_pedge;
    edge_detector_n ed_timeout(.clk(clk), 
                               .reset_p(reset_p), 
                               .cp(eoc_out), 
                               .p_edge(eoc_out_pedge) );
    reg [11:0] adc_value;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) adc_value = 0;
        else if (eoc_out_pedge) begin // eoc_out 의 p edge가 adc값을 발생하면 adc_value에 저장
            adc_value = do_out[15:4];
        end
    end

/*
ADC모듈 자체는 0~1V를 12비트로 나누어 0~4095로 표현
Cora, basys는 별도의 회로가 구성되어 있어 0~1V를 0~3.3V로 변환
*/

    wire clk_usec, clk_msec, clk_Nmsec;
    clock_usec #(125) usec(clk, reset_p, clk_usec);
    clock_div_1000 msec(clk, reset_p, clk_usec, clk_msec);
    // clock_div_N #(5) Nmsec(clk, reset_p, clk_msec, clk_Nmsec);

    // localparam offset = 50;
    reg [11:0] pwm_duty;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            pwm_duty = 0 /*offset*/ ;
        end
        else begin
            if (clk_msec) begin
                pwm_duty = {4'b0, adc_value[11:4]} /* + offset*/;
            end
        end
    end

    pwm_controller #(125, 8) pwm_o(.clk(clk),
                         .reset_p(reset_p),
                         .duty(pwm_duty[7:0]),
                         .pwm_freq(50),
                         .pwm(motor_pwm) );
    wire [15:0] fnd_out; 
    // do_out[15:4] 하위 4비트는 사용하지 않음
    bin_to_dec btd(.bin(pwm_duty), .bcd(fnd_out));

    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset_p), 
                               .value           (fnd_out),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );
endmodule

/*
-- Running Average

이전 n개의 평균을 구하는 방법

XADC 설정에서  Channel Averaging을 설정하면 Running Average 모드로 동작함
*/

/*
ADC는 1개만 들어있으므로 
1개를 시퀀서로 여러 채널을 읽을 수 있도록 설정함
*/

module joystick_test_top(
    input clk, reset_p,
    input vauxn6, vauxp6, vauxn15, vauxp15,
    input [3:0]btn,
    output reg [7:0] led_bar,
    output pwm_blue, pwm_green,
    output [3:0] com,
    output [7:0] seg_7   
    );

    wire [4:0] channel_out;
    wire [15:0] do_out;
    wire eoc_out, eos_out;
    adc_ch6_ch15 adc_2ch(
          .daddr_in({2'b0, channel_out}),
          .dclk_in(clk), // clk
          .den_in(eoc_out), // 변환이 끝나면 활성화
          .reset_in(reset_p),
          .vauxp6(vauxp6),
          .vauxn6(vauxn6),
          .vauxp15(vauxp15),
          .vauxn15(vauxn15),
          .channel_out(channel_out),     // 채널 마다 다르므로 주의
          .do_out(do_out), // ADC 값
          .eoc_out(eoc_out),           // 채널 1개가 스캔 되면 End of Conversion 발생
          .eos_out(eos_out)         ); // 모든채널이 스캔 되면 End of sequance 발생

    //eoc_out 엣지 디텍터
    wire eoc_out_pedge;
    edge_detector_n  eoc_ed(.clk(clk),
                            .reset_p(reset_p),
                            .cp(eoc_out),
                            .p_edge(eoc_out_pedge) );
    
    /*
    //eos_out 엣지 디텍터
    wire eos_out_pedge;
    edge_detector_n  eos_ed(.clk(clk),
                            .reset_p(reset_p),
                            .cp(eos_out),
                            .p_edge(eos_out_pedge) );

    // ADC의 타이밍이 맞아야 하는경우 eos_out을 사용하여 ADC값이 동시에 바뀌도록 함
    reg [6:0] duty_x, duty_y;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            duty_x = 0;
            duty_y = 0;
        end
        ense begin
            if (eos_out_pedge) begin
                duty_x = adc_value_x[6:0];
                duty_y = adc_value_y[6:0];
            end
        end
    end
    */

    // ADC 채널 2개를 읽어서 저장
    reg [11:0] adc_value_x, adc_value_y;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin 
            adc_value_x = 0;
            adc_value_y = 0;
        end
        else begin // eoc_out 의 p edge가 adc값을 발생하면 adc_value에 저장
            if (eoc_out_pedge) begin
                // channel_out 의 최상위비트가 1이 붙어 나오므로 4비트만 사용
                case (channel_out[3:0]) // channel_out에 따라서 adc_value_x, adc_value_y에 저장
                    4'd6 : adc_value_x = do_out[15:4];
                    4'd15 : adc_value_y = do_out[15:4];
                    default : begin 
                        adc_value_x = adc_value_x; 
                        adc_value_y = adc_value_y;
                    end               
                endcase
            end
        end
    end 



    wire [15:0] fnd_out; 
    wire [11:0] bin_data;
    wire toggle_xy;
    wire [3:0] btn_p;
    // x,y 토글 버튼
    edge_detector_n ed_toggle(.clk(clk), .reset_p(reset_p), .cp(btn[0]), .p_edge(btn_p[0]) );
    T_flip_flop_p TFF_xy_tog(clk, reset_p, btn_p[0], toggle_xy);
    assign bin_data = toggle_xy ? adc_value_x : adc_value_y;
    bin_to_dec btd(.bin(bin_data), .bcd(fnd_out));

    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset_p), 
                               .value           (fnd_out),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) led_bar = 8'b0000_0000;
        else begin
            if (eoc_out_pedge) begin
                led_bar = (adc_value_x > 3583) ? 8'b1111_1111 :
                          (adc_value_x > 3071) ? 8'b0111_1111 :
                          (adc_value_x > 2559) ? 8'b0011_1111 :
                          (adc_value_x > 2047) ? 8'b0001_1111 :
                          (adc_value_x > 1535) ? 8'b0000_1111 :
                          (adc_value_x > 1023) ? 8'b0000_0111 :
                          (adc_value_x > 511 ) ? 8'b0000_0011 : 8'b0000_0001;
            end
        end
    end

    //RGB LED 출력
    pwm_controller #(125, 12) pwm_b(.clk(clk),
                                    .reset_p(reset_p),
                                    .duty(adc_value_x),
                                    .pwm_freq(60),
                                    .pwm(pwm_blue) );
    
    pwm_controller #(125, 12) pwm_g(.clk(clk),
                                    .reset_p(reset_p),
                                    .duty(adc_value_y),
                                    .pwm_freq(60),
                                    .pwm(pwm_green) );
endmodule


module i2c_master_test_top (
	input clk, reset_p,
    input [1:0] btn,
    output [7:0] led_bar,
    output sda, scl );


    wire [1:0] btn_p, btn_n;
    button_cntr btn_0(clk, reset_p, btn[0], btn_p[0], btn_n[0]);
    button_cntr btn_1(clk, reset_p, btn[1], btn_p[1], btn_n[1]);

    reg [7:0] data;
    reg valid;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            data <= 8'b0000_0000;
            valid <= 1'b0;
        end
        else begin
            if (btn_p[0]) begin
                data <= 8'b0000_0000;
                valid <= 1'b1;
            end
            else if (btn_n[0]) begin
                valid <= 1'b0;
            end

            else if (btn_p[1]) begin
                data <= 8'b0000_1000;
                valid <= 1'b1;    
            end
            else if (btn_n[1]) begin
                valid <= 1'b0;
            end
        end
    end
/*
{data, bt, en, rw, rs}
 D7 |D6 |D5 |D4 |BT |EN |RW | RS
[ 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 ]

4bit mode
주소 상위 4비트 보내고
en 1->0
주소 하위 4비트 보내기
en 1->0
데이터(명령) 상위 4비트 보내고
en 1->0
데이터(명령) 하위 4비트 보내기
en 1->0

{addr + W} = 0x27 = 0100_1110
en : 0x04

*/
    i2c_master i2c_mst( .clk       (clk),
                        .reset_p   (reset_p),
                        .rd_wr     (1'b0),
                        .addr      (7'h27),
                        .data_in   (data),
                        .valid     (valid),
                        .led_bar   (led_bar),
                        .sda       (sda),
                        .scl       (scl)        );


endmodule


module i2c_lcd_init (
    input clk, reset_p,
    input [1:0] btn,
    output sda, scl,
    output [7:0] led_bar,
    output [7:0] seg_7,
    output [3:0] com     );



    localparam ADDR = 7'h27;

    localparam S_IDLE                   = 14'b00_0000_0000_0001;
    localparam S_DELAY_15MS             = 14'b00_0000_0000_0010;
    localparam S_FUNCTION_SET_1         = 14'b00_0000_0000_0100;
    localparam S_DELAY_4_1MS            = 14'b00_0000_0000_1000;
    localparam S_FUNCTION_SET_2         = 14'b00_0000_0001_0000;
    localparam S_DELAY_100US            = 14'b00_0000_0010_0000;
    localparam S_FUNCTION_SET_3         = 14'b00_0000_0100_0000;
    localparam S_FUNCTION_SET_4         = 14'b00_0000_1000_0000;
    localparam S_CMD_4_BIT_MODE         = 14'b00_0001_0000_0000;
    localparam S_CMD_DISPLAY_OFF        = 14'b00_0010_0000_0000;
    localparam S_CMD_DISPLAY_CLR        = 14'b00_0100_0000_0000;
    localparam S_CMD_ENTRY_MODE_SET     = 14'b00_1000_0000_0000;
    localparam S_CMD_DISPLAY_ON         = 14'b01_0000_0000_0000;

    localparam CMD_4BIT_MODE            = 8'h28;
    localparam CMD_DISPLAY_OFF          = 8'h08;
    localparam CMD_DISPLAY_CLR          = 8'h01;
    localparam CMD_ENTRY_MODE_SET       = 8'h06;
    localparam CMD_DISPLAY_ON           = 8'h0C;


    reg rs; // 0: command, 1: data
    reg send;
    reg [7:0] data;
    wire [7:0] data_out;
    wire valid, busy_flag;

    wire [1:0] btn_p, btn_n;
    button_cntr btn_0(clk, reset_p, btn[0], btn_p[0], btn_n[0]);
    button_cntr btn_1(clk, reset_p, btn[1], btn_p[1], btn_n[1]);
    
    //usec 카운터
    wire clk_usec;
    reg clk_usec_e;
    clock_usec #(125) usec(clk, reset_p, clk_usec);

    reg [13:0] cnt_usec;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_usec <= 0;
        end
        else begin
            if (clk_usec_e) begin
                if (clk_usec) cnt_usec <= cnt_usec + 1;
            end
            else begin
                cnt_usec <= 0;
            end
        end
    end

    //msec 카운터
    wire clk_msec;
    reg clk_msec_e;
    clock_div_1000 msec(clk, reset_p, clk_usec, clk_msec);

    reg [13:0] cnt_msec;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_msec <= 0;
        end
        else begin
            if (clk_msec_e) begin
                if (clk_msec) cnt_msec <= cnt_msec + 1;
            end
            else begin
                cnt_msec <= 0;
            end
        end
    end

    reg [13:0] state, next_state;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            data <= 8'b0;
            send <= 1'b0;
            rs <= 1'b0;
            clk_usec_e <= 1'b0;
            clk_msec_e <= 1'b0;
            next_state <= S_IDLE;
        end
        else begin
            if (btn_p[1]) begin
                data <= 8'h3F;
                rs <= 1'b1;
                send <= 1'b1;
            end
            else begin

            case (state)
                S_IDLE : begin
                    data <= 8'b0;
                    send <= 1'b0;
                    rs <= 1'b0;
                    if (btn_p[0]) begin
                        next_state <= S_DELAY_15MS;
                    end
                    else begin
                        next_state <= S_IDLE;
                    end
                end

                S_DELAY_15MS : begin
                    if (cnt_msec >= 20) begin
                        clk_msec_e <= 1'b0;
                        next_state <= S_FUNCTION_SET_1;
                    end
                    else begin
                        clk_msec_e <= 1'b1;
                    end 
                end

                S_FUNCTION_SET_1 : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= 8'h03;
                        send <= 1'b1;
                        next_state <= S_DELAY_4_1MS;
                    end
                    else begin
                        next_state <= S_FUNCTION_SET_1;
                        send <= 1'b0;
                    end                     
                end

                S_DELAY_4_1MS : begin
                    if (cnt_msec >= 6) begin
                        clk_msec_e <= 1'b0;
                        next_state <= S_FUNCTION_SET_2;
                    end
                    else begin
                        clk_msec_e <= 1'b1;
                    end 
                end
  
                S_FUNCTION_SET_2 : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= 8'h03;
                        send <= 1'b1;
                        next_state <= S_DELAY_100US;
                    end
                    else begin
                        next_state <= S_FUNCTION_SET_2;
                        send <= 1'b0;
                    end                     
                end  

                S_DELAY_100US : begin
                    if (cnt_usec >= 200) begin
                        clk_usec_e <= 1'b0;
                        next_state <= S_FUNCTION_SET_3;
                    end
                    else begin
                        clk_usec_e <= 1'b1;
                    end 
                end    

                S_FUNCTION_SET_3 : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= 8'h03;
                        send <= 1'b1;
                        next_state <= S_FUNCTION_SET_4;
                    end
                    else begin
                        next_state <= S_FUNCTION_SET_3;
                        send <= 1'b0;
                    end                     
                end     

                S_FUNCTION_SET_4 : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= 8'h03;
                        send <= 1'b1;
                        next_state <= S_CMD_4_BIT_MODE;
                    end
                    else begin
                        next_state <= S_FUNCTION_SET_4;
                        send <= 1'b0;
                    end                     
                end

                S_CMD_4_BIT_MODE : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= CMD_4BIT_MODE;
                        send <= 1'b1;
                        next_state <= S_CMD_DISPLAY_OFF;
                    end
                    else begin
                        next_state <= S_CMD_4_BIT_MODE;
                        send <= 1'b0;
                    end                     
                end  
                   
                S_CMD_DISPLAY_OFF : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= CMD_DISPLAY_OFF;
                        send <= 1'b1;
                        next_state <= S_CMD_DISPLAY_CLR;
                    end
                    else begin
                        next_state <= S_CMD_DISPLAY_OFF;
                        send <= 1'b0;
                    end                     
                end 

                S_CMD_DISPLAY_CLR  : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= CMD_DISPLAY_CLR;
                        send <= 1'b1;
                        next_state <= S_CMD_ENTRY_MODE_SET;
                    end
                    else begin
                        next_state <= S_CMD_DISPLAY_CLR;
                        send <= 1'b0;
                    end                     
                end 
                
                S_CMD_ENTRY_MODE_SET  : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= CMD_ENTRY_MODE_SET;
                        send <= 1'b1;
                        next_state <= S_CMD_DISPLAY_ON;
                    end
                    else begin
                        next_state <= S_CMD_ENTRY_MODE_SET;
                        send <= 1'b0;
                    end                     
                end 

                S_CMD_DISPLAY_ON  : begin
                    if (busy_flag==0) begin // busy_flag가 0이 되기를 대기함
                        data <= CMD_DISPLAY_ON;
                        send <= 1'b1;
                        next_state <= S_IDLE;
                    end
                    else begin
                        next_state <= S_CMD_DISPLAY_ON;
                        send <= 1'b0;
                    end                     
                end  

            endcase
            
            end
        end
    end

    i2c_lcd_tx_byte i2c_lcd_tx( .clk           (clk),
                                .reset_p       (reset_p),
                                .send_buffer   (data),     // 보낼 데이터
                                .send          (send),   // 통신 시작 신호
                                .rs            (rs),       // 0: command, 1: data
                                .data_out      (data_out), // tx module로 보낼 데이터
                                .valid         (valid),
                                .busy_flag     (busy_flag)  );    // tx module로 송신 on off 
    
    
    i2c_transmit_addr_byte i2c_tx( .clk        (clk),
                                   .reset_p    (reset_p),
                                   .addr       (ADDR),
                                   .rs         (rs),
                                   .data_in    (data_out),
                                   .valid      (valid),
                                   .sda        (sda),
                                   .scl        (scl) );

    assign led_bar = {busy_flag, state[6:0]};
    wire [15:0] fnd_out; 
    // do_out[15:4] 하위 4비트는 사용하지 않음
    bin_to_dec btd(.bin({4'b0, data_out}), .bcd(fnd_out));

    fnd_4_digit_cntr      fnd (.clk             (clk), 
                               .reset_p         (reset_p), 
                               .value           (fnd_out),
                               .segment_data_ca (seg_7), 
                               .com_sel         (com) );

endmodule

module i2c_test (
    input clk, reset_p,
    input [1:0] btn,
    output sda, scl
);

    localparam ADDR = 8'h27;

    wire [1:0] btn_p, btn_n;
    button_cntr btn_0(clk, reset_p, btn[0], btn_p[0], btn_n[0]);
    button_cntr btn_1(clk, reset_p, btn[1], btn_p[1], btn_n[1]);

    reg [7:0] data;
    reg rs;
    reg send;
    // reg valid;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            data <= 8'b0;
            rs <= 0;
            send <= 1'b0;   
            // valid <= 1'b0;         
        end
        else begin
            if (btn_p[0]) begin
                data <= 8'hFF;
                rs   <= 1'b0;
                send <= 1'b1; 
                // valid <= 1'b1;
            end
            else if (btn_p[1]) begin
                data <= 8'h00;
                rs   <= 1'b0;
                send <= 1'b1; 
                // valid <= 1'b1;
            end
            else begin 
                send <= 1'b0;
                // valid <= 1'b0;
            end
        end
    end

    i2c_lcd_tx_byte i2c_lcd_tx( .clk           (clk),
                                .reset_p       (reset_p),
                                .send_buffer   (data),     // 보낼 데이터
                                .send          (send),   // 통신 시작 신호
                                .rs            (rs),       // 0: command, 1: data
                                .data_out      (data_out), // tx module로 보낼 데이터
                                .valid         (valid),
                                .busy_flag     (busy_flag)  );    // tx module로 송신 on off 
    i2c_master i2c( .clk(clk),
                    .reset_p(reset_p),
                    .rs(rs),
                    .addr(ADDR),
                    .data_in(data_out),
                    .valid(valid),
                    .sda(sda),
                    .scl(scl) );
    /*
    i2c_transmit_addr_byte i2c_tx( .clk        (clk),
                                   .reset_p    (reset_p),
                                   .addr       (ADDR),
                                   .rs         (rs),
                                   .data_in    (data),
                                //    .data_in    (data_out),
                                   .valid      (valid),
                                   .sda        (sda),
                                   .scl        (scl) );
                                   */
endmodule