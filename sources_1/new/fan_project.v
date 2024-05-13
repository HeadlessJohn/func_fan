`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module project_1(
    input clk, reset_p,
    input [2:0] btn,
    inout dht11_data,
    output [7:0] led_bar,
    output pwm, led,
    output [3:0] com,
    output [7:0] seg_7,
    output sda, scl    );
    
    wire [7:0] fan_led, timer_led;
    wire [19:0] cur_time;
    assign led_bar = {fan_led[4:1], timer_led[3:0]};
    wire fan_en, run_e;
    wire [7:0] fan_speed;
    wire [3:0] fan_timer_state;

    fan_info lcd( .clk          (clk),
                  .reset_p      (reset_p),
                  .dht11_data   (dht11_data),
                  .fan_speed    (fan_speed),
                  .fan_timer_state(fan_timer_state),
                  .sda          (sda), 
                  .scl          (scl),
                  .time_h_1     (cur_time[19:16]),
                  .time_m_10    (cur_time[15:12]),
                  .time_m_1     (cur_time[11:8]),
                  .time_s_10    (cur_time[7:4]),
                  .time_s_1     (cur_time[3:0])    );
            

    fan_controller #(125, 12) (.clk(clk), .reset_p(reset_p), .btn(btn[0]), .fan_en(fan_en), .state(fan_speed), .pwm(pwm), .run_e(run_e));
    led_controller (clk, reset_p, btn[1], led);
    
    fan_timer(clk, reset_p, btn[2], run_e, alarm, fan_timer_state, timeout_pedge, cur_time, timer_led);
   
    assign fan_en = timeout_pedge ? 0 : 1;
    
    fnd_4_digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(cur_time[15:0]), .segment_data_ca(seg_7), .com_sel(com));
    
endmodule


module fan_controller #(SYS_FREQ = 125, N = 12) (
    input clk, reset_p,
    input btn,              // 버튼 입력
    input fan_en,           // 팬 동작 enable 신호
    output reg [7:0] state,       // 현재 동작 state 표시
    output pwm, 
    output reg run_e);         // 출력 PWM 신호

    //state 정의
    localparam S_IDLE = 8'b0000_0001;
    localparam S_1    = 8'b0000_0010;
    localparam S_2    = 8'b0000_0100;
    localparam S_3    = 8'b0000_1000;
    localparam S_4    = 8'b0001_0000;
    localparam S_5    = 8'b0010_0000;
    localparam S_6    = 8'b0100_0000;
    localparam S_7    = 8'b1000_0000;

    // 버튼 입력부 컨트롤러
    wire btn_p;
    button_cntr btn0(clk, reset_p, btn, btn_p);
        
    // FSM 
    reg [7:0] next_state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    // btn 입력에 따른 state 변경 로직
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= S_IDLE;
        end
        else begin
            if (fan_en) begin // fan_en이 활성화 되었을 때만 동작
                if (btn_p) begin
                    next_state <= {state[6:0], state[7]}; // state를 1비트씩 shift하여 다음 state로 이동
                end 
            end
            else begin // fan_en이 0인 경우 IDLE 상태로 이동- fan 멈춤
                next_state <= S_IDLE;
            end
        end
    end

    // state 별 듀티 제어
    reg [N-1:0] fan_duty;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            fan_duty <= 0;
        end
        else begin
            case (state)
                S_IDLE : begin
                    fan_duty <= 0;
                    run_e = 0;
                end

                S_1 : begin
                    fan_duty <= 1023;
                    run_e = 1;
                end

                S_2 : begin
                    fan_duty <= 1535;
                end

                S_3 : begin
                    fan_duty <= 2047;
                end

                S_4 : begin
                    fan_duty <= 2559;
                end

                S_5 : begin
                    fan_duty <= 3071;
                end

                S_6 : begin
                    fan_duty <= 3583;
                end

                S_7 : begin
                    fan_duty <= 4095;
                end
            endcase
        end
    end

    //PWM 출력 모듈
    //200Hz 0~4095 듀티
    pwm_controller #(SYS_FREQ, N) (.clk(clk),
                                   .reset_p(reset_p),
                                   .duty(fan_duty), //0~4095
                                   .pwm_freq(200),
                                   .pwm(pwm)
                                   );
endmodule

module clk_set(
    input clk, reset_p,
    output clk_msec, clk_csec, clk_sec, clk_min);

    clock_usec usec_clk(clk, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_10 csec_clk(clk, reset_p, clk_msec, clk_csec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk, reset_p, clk_sec, clk_min);

endmodule

// module pwm_controller #(
//     parameter SYS_FREQ = 125, //125MHz
//     parameter N = 12 // 2^7 = 128단계
//     )(
//     input clk, reset_p,
//     input [N-1:0] duty, //N비트의 duty비트
//     input [13:0] pwm_freq,
//     output reg pwm    );

//     localparam REAL_SYS_FREQ = SYS_FREQ * 1000 * 1000;

//     reg [26:0] cnt;
//     reg pwm_clk_nbit; // 
    
//     //clock에 관계 없는 부분이므로 나눗셈을 사용해도 negative slack이 발생하지 않음
//     //처음에 나눗셈을 계산하는동안 긴 pdt 시간 동안 오동작 발생 가능성 있음
//     wire [26:0] temp;
//     assign temp = (REAL_SYS_FREQ /pwm_freq);

//     always @(posedge reset_p, posedge clk) begin
//         if (reset_p) begin
//             pwm_clk_nbit <= 0;
//             cnt <= 0;
//         end
//         else begin
//             // 128단계 제어 -> 2^7로 나누므로 우쉬프트 연산으로 대체 가능
//             if (cnt >= temp[26:N] - 1) begin
//             // 100단계 제어
//             // if (cnt >= REAL_SYS_FREQ /pwm_freq /100 - 1) begin
//                 cnt <= 0;
//                 pwm_clk_nbit <= 1'b1;
//             end
//             else begin
//                 pwm_clk_nbit <= 1'b0;
//             end
//             cnt = cnt + 1;

//         end
//     end

//     reg [N-1:0] cnt_duty;
//     always @(posedge reset_p, posedge clk) begin
//         if (reset_p) begin
//             pwm <= 1'b0;
//             cnt_duty <= 0;
//         end
//         else begin
//             if (pwm_clk_nbit) begin
//                 //2^N단계로 제어
//                 cnt_duty <= cnt_duty + 1;
//                 if(cnt_duty < duty) pwm <= 1'b1;
//                 else pwm <= 1'b0;
//             end           
//         end
//     end
// endmodule

module fan_timer(
    input clk, reset_p,
    input btn,
    input run_e,
    output reg alarm, 
    output reg [3:0] state,
    output timeout_pedge,
    output [19:0] cur_time,
    output [3:0] led_bar);
    
    parameter OFF          = 4'b0001;
    parameter ONE          = 4'b0010;
    parameter THREE        = 4'b0100;
    parameter FIVE         = 4'b1000;
    
    wire btn_pedge, btn_nedge;
    button_cntr ed0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_p_edge(btn_pedge), .btn_n_edge(btn_nedge));
    
    reg [3:0]next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = OFF;
        else state = next_state;
    end
    
    assign led_bar = state;
    
    reg clk_en;
    reg [3:0] set_value;
    assign clk_start = clk_en ? clk : 0;
    
    down_timer down(.clk(clk_start), .reset_p(reset_p), .load_enable(btn_nedge), .set_value(set_value), .cur_time(cur_time));
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= OFF;
        end
        else begin
            if (run_e) begin // fan_en이 활성화 되었을 때만 동작
                if (btn_pedge) begin
                    next_state <= {state[2:0], state[3]}; // state를 1비트씩 shift하여 다음 state로 이동
                end 
            end
            else begin // fan_en이 0인 경우 IDLE 상태로 이동- fan 멈춤
                next_state <= OFF;
            end
        end
    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            clk_en = 0;
        end
        else begin
            case(state)
            OFF:begin
                clk_en = 0;
            end
            ONE:begin
                clk_en = 1;
                set_value = 1;
            end
            THREE:begin
                set_value = 3;
            end
            FIVE:begin
                set_value = 5;
            end
            endcase
        end
    end

    always @(posedge clk or posedge reset_p)begin
        if(reset_p) alarm = 0;
        else begin
            if(cur_time==0) alarm = 1;
            else alarm = 0;
        end
    end

    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(alarm), .p_edge(timeout_pedge));

endmodule

module down_timer(
    input clk, reset_p,
    input load_enable,
    input [3:0] set_value,
    output [19:0] cur_time);
    
    wire clk_sec, clk_sec10, clk_min1, clk_min10, clk_hour;
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10, cur_hour;

    clk_set(clk, reset_p, clk_msec, clk_csec, clk_sec, clk_min);
   // assign clk_en = (cur_time == 0) ? 1'b0 : 1'b1;
  //  assign clk_sec_out = clk_en ? clk_sec : 0;
    
    load_count_ud_N #(10) sec1(.clk(clk), .reset_p(reset_p), .clk_dn(clk_sec),
        .data_load(load_enable), .set_value(0), .digit(cur_sec1), .clk_under_flow(clk_sec10));
    load_count_ud_N #(6) sec10(.clk(clk), .reset_p(reset_p), .clk_dn(clk_sec10),
        .data_load(load_enable), .set_value(set_value), .digit(cur_sec10), .clk_under_flow(clk_min1));
    load_count_ud_N #(10) min1(.clk(clk), .reset_p(reset_p), .clk_dn(clk_min1),
        .data_load(load_enable), .set_value(0), .digit(cur_min1), .clk_under_flow(clk_min10));
    load_count_ud_N #(6) min10(.clk(clk), .reset_p(reset_p), .clk_dn(clk_min10),
        .data_load(load_enable), .set_value(0), .digit(cur_min10), .clk_under_flow(clk_hour));
    load_count_ud_N #(10) hour(.clk(clk), .reset_p(reset_p), .clk_dn(clk_hour),
        .data_load(load_enable), .set_value(0), .digit(cur_hour), .clk_under_flow());
    
    assign cur_time = {cur_hour, cur_min10, cur_min1, cur_sec10, cur_sec1};
        
endmodule

// module load_count_ud_N #(
//     parameter N = 10 )(
//     input clk, reset_p,
//     input clk_up,
//     input clk_dn,
//     input data_load,
//     input [3:0] set_value,
//     output reg [3:0] digit,
//     output reg clk_over_flow,
//     output reg clk_under_flow);

//     always @(posedge clk, posedge reset_p) begin
//         if (reset_p) begin
//             digit = 0;
//             clk_over_flow = 0;
//             clk_under_flow = 0;
//         end
//         else begin
//             if (data_load) begin
//                 digit = set_value;
//             end
//             else if (clk_up) begin
//                 if (digit >= (N-1)) begin 
//                     digit = 0; 
//                     clk_over_flow = 1;
//                 end
//                 else begin digit = digit + 1;
//                 end
//             end
//             else if (clk_dn) begin
//                 digit = digit - 1;
//                 if (digit > (N-1)) begin
//                     digit = (N-1);
//                     clk_under_flow = 1;
//                 end
//             end
//             else begin 
//                 clk_over_flow = 0;
//                 clk_under_flow = 0;
//             end
//         end
//     end
// endmodule

module led_controller(
    input clk, reset_p,
    input btn,
    output led);
    
    parameter IDLE      = 4'b0001;      // OFF
    parameter LED_1STEP = 4'b0010;      // 1단계
    parameter LED_2STEP = 4'b0100;      // 2단계
    parameter LED_3STEP = 4'b1000;      // 3단계
    
    wire btn_pedge;
    button_cntr btn_ctrl(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_p_edge(btn_pedge));
    
    reg [6:0] duty;    
    reg [3:0] state;      // led_ringcounter
    always @(posedge clk, posedge reset_p) begin
        if(reset_p)begin
            state = IDLE;
            duty = 0;
        end
        else if(btn_pedge)begin
            if(state == IDLE)begin
                state = LED_1STEP;
                duty = 13;
            end
            else if(state == LED_1STEP)begin
                state = LED_2STEP;
                duty = 38;
            end
            else if(state == LED_2STEP)begin
                state = LED_3STEP;
                duty = 64;
            end
            else begin
                state = IDLE;
                duty = 0;
            end
        end
    end
    
    pwm_controller #(125, 9) (.clk(clk),
                              .reset_p(reset_p),
                              .duty(duty),
                              .pwm_freq(100),
                              .pwm(led)
                              );    
endmodule