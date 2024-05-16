`timescale 1us / 1ns
//////////////////////////////////////////////////////////////////////////////////

module project_1(
    input        clk, 
    input        reset_p,
    input  [3:0] btn,
    input        clap,
    input        echo,
    inout        dht11_data,

    // output [3:0] com,       //for debug
    // output [7:0] seg_7,     //for debug
    output [7:0] led_bar,   //for debug

    output       trig,      // 초음파센서 트리거
    output       servo_pwm, // 좌우 회전 기능
    output       pwm, 
    output       led,
    output       buz_clk,
    output       sda,
    output       scl    );

    localparam SYS_FREQ              = 125;      // 125MHz
    localparam BTN_HOLD_TIME         = 700_000;  // 700ms
    localparam BTN_DOUBLE_TAP_TIME   = 100_000;  // 100ms
    
    wire        fan_en;
    wire        run_e;
    wire [7:0]  fan_led;
    wire [7:0]  timer_led;
    wire [19:0] cur_time;
    wire [7:0]  fan_speed;
    wire [3:0]  fan_timer_state;
    wire [3:0]  btn_single;
    wire [3:0]  btn_double; 
    wire [3:0]  btn_long;
    assign      fan_en = timeout_pedge ? 0 : 1;
    // assign      led_bar = {fan_led[4:1], timer_led[3:0]};
    reg         buz_on;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            buz_on <= 0;
        end
        else begin
            if(timeout_pedge)begin
                buz_on <= 1;
            end
            if(btn) begin
                buz_on <= 0;
            end
        end
    end

    fan_info lcd( .clk            (clk),
                  .reset_p        (reset_p),
                  .dht11_data     (dht11_data),
                  .fan_speed      (fan_speed),
                  .fan_timer_state(fan_timer_state),
                  .sda            (sda), 
                  .scl            (scl),
                  .time_h_1       (cur_time[19:16]),
                  .time_m_10      (cur_time[15:12]),
                  .time_m_1       (cur_time[11: 8]),
                  .time_s_10      (cur_time[ 7: 4]),
                  .time_s_1       (cur_time[ 3: 0])    );

    wire sencer;
    ultra_sonic_controller us_inst(.clk     (clk),
                                   .reset_p (reset_p),
                                   .echo    (echo),
                                   .trig    (trig),
                                   .sencer  (sencer)  );
    assign led_bar = {7'b0, sencer};
    wire clap_single, clap_double;
    clap_controller clap_inst (.clk     (clk),
                               .reset_p (reset_p),
                               .clap    (clap),
                               .single  (clap_single),
                               .double  (clap_double)  );
    
    btn_double_long #(BTN_HOLD_TIME, BTN_DOUBLE_TAP_TIME) btn_fan_cntr  (.clk     (clk), 
                                                                         .reset_p (reset_p), 
                                                                         .btn     (btn[0]),
                                                                         .single  (btn_single[0]), 
                                                                         .double  (btn_double[0]), 
                                                                         .long    (btn_long[0])    );
                  
    btn_double_long #(BTN_HOLD_TIME, BTN_DOUBLE_TAP_TIME) btn_led_cntr  (.clk     (clk), 
                                                                         .reset_p (reset_p), 
                                                                         .btn     (btn[1]),
                                                                         .single  (btn_single[1]), 
                                                                         .double  (btn_double[1]), 
                                                                         .long    (btn_long[1])    );

    btn_double_long #(BTN_HOLD_TIME, BTN_DOUBLE_TAP_TIME) btn_servo_cntr(.clk     (clk), 
                                                                         .reset_p (reset_p), 
                                                                         .btn     (btn[3]),
                                                                         .single  (btn_single[3]), 
                                                                         .double  (btn_double[3]), 
                                                                         .long    (btn_long[3])    );

    wire set_fan_idle;
    wire wind_inc;
    assign set_fan_idle = btn_long[0] || clap_double || sencer; // 두번박수로 팬 멈추기, 초음파센서로 팬 멈추기
    assign wind_inc = btn_single[0] || clap_single; // 한번박수로 바람세기 증가
    fan_controller #(SYS_FREQ, 12) (.clk      (clk), 
                                    .reset_p  (reset_p), 
                                    .btn      (wind_inc), 
                                    .btn_back (btn_double[0]),
                                    .set_idle (set_fan_idle),
                                    .fan_en   (fan_en), 
                                    .state    (fan_speed), 
                                    .pwm      (pwm), 
                                    .run_e    (run_e));
    // wire [11:0] duty_out;
    wire rot_en;
    assign rot_en = ~fan_speed[0];
    servo_rotation servo_inst(.clk        (clk), 
                              .reset_p    (reset_p), 
                              .start_stop (btn_single[3]), 
                              .rot_toggle (btn_double[3]), 
                              .btn_long   (btn_long[3]), 
                              .rot_en     (rot_en),
                            //   .duty_out   (duty_out),
                              .motor_pwm  (servo_pwm) );

    buz_top buzz(.clk     (clk), 
                 .reset_p (reset_p), 
                 .buz_on  (buz_on), 
                 .buz_clk (buz_clk) );

    led_controller led_cntr(clk, reset_p, btn_single[1], btn_long[1], led);
    fan_timer fan_tmr(clk, reset_p, btn[2], run_e, alarm, fan_timer_state, timeout_pedge, cur_time, timer_led);

    // fnd_4_digit_cntr fnd(.clk             (clk), 
    //                      .reset_p         (reset_p), 
    //                      .value           ({4'b0,duty_out}), 
    //                      .segment_data_ca (seg_7), 
    //                      .com_sel         (com) );
endmodule


// 문자열 보내는 모듈
module uart_tx_string (
    input clk,
    input reset_p,
    input send_enable, // 시작 신호
    input tx_done, // tx_done 입력 받음
    input [255:0] string, //32자
    input [5:0] string_len, //문자열 길이
    output reg [7:0] char,
    output reg tx_signal );

    localparam IDLE    = 8'b0000_0001,
               READY   = 8'b0000_0010,
               SEND    = 8'b0000_0100;

    reg [7:0] str_parse[31:0];
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
        end
        else begin
            if (send_enable) begin // 문자열 전송 시작 신호 받으면 배열에 정리함
                str_parse[31] <= string[255:248];
                str_parse[30] <= string[247:240];
                str_parse[29] <= string[239:232];
                str_parse[28] <= string[231:224];
                str_parse[27] <= string[223:216];
                str_parse[26] <= string[215:208];
                str_parse[25] <= string[207:200];
                str_parse[24] <= string[199:192];
                str_parse[23] <= string[191:184];
                str_parse[22] <= string[183:176];
                str_parse[21] <= string[175:168];
                str_parse[20] <= string[167:160];
                str_parse[19] <= string[159:152];
                str_parse[18] <= string[151:144];
                str_parse[17] <= string[143:136];
                str_parse[16] <= string[135:128];
                str_parse[15] <= string[127:120];
                str_parse[14] <= string[119:112];
                str_parse[13] <= string[111:104];
                str_parse[12] <= string[103: 96];
                str_parse[11] <= string[ 95: 88];
                str_parse[10] <= string[ 87: 80];
                str_parse[ 9] <= string[ 79: 72];
                str_parse[ 8] <= string[ 71: 64];
                str_parse[ 7] <= string[ 63: 56];
                str_parse[ 6] <= string[ 55: 48];
                str_parse[ 5] <= string[ 47: 40];
                str_parse[ 4] <= string[ 39: 32];
                str_parse[ 3] <= string[ 31: 24];
                str_parse[ 2] <= string[ 23: 16];
                str_parse[ 1] <= string[ 15:  8];
                str_parse[ 0] <= string[  7:  0];
            end
        end
    end

    reg [7:0] state, next_state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            state <= 0;
        end
        else begin
            state <= next_state;
        end
    end

    reg [4:0] i;
    reg busy_flag;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= IDLE;
            i <= 0;
            tx_signal <= 0;
            char <= 0;
            busy_flag <= 0;
        end
        else begin
            case (state) 
                IDLE : begin
                    if (send_enable) begin 
                        next_state <= SEND;
                        busy_flag <= 1;
                    end
                    else begin
                        tx_signal  <= 0;
                    end
                end

                READY : begin
                    if (tx_done) next_state <= SEND;
                    else         tx_signal  <= 0;
                end

                SEND : begin
                    if (i >= string_len) begin
                        next_state <= IDLE;
                        busy_flag <= 0;
                        i <= 0;
                    end
                    else begin
                        char <= str_parse[string_len -1 -i];
                        tx_signal <= 1;
                        i <= i + 1;
                        next_state <= READY;
                    end
                end
            endcase
        end
    end
    
endmodule


module uart_tx_string_test (
    input clk,
    input reset_p,
    input [3:0] btn,
    output uart_tx );

    wire [7:0] char;
    reg [255:0] string = "ABCDEFGHIJKLMNOPQRSTUVWXYZ789012";
    reg [5:0] string_len = 32;

    wire [3:0]btn_single;
    btn_double_long  btn_fan_cntr (.clk     (clk), 
                                   .reset_p (reset_p), 
                                   .btn     (btn[0]),
                                   .single  (btn_single[0])  );

    uart_tx_string uart_tx_string_inst ( .clk         (clk),
                                         .reset_p     (reset_p),
                                         .send_enable (btn_single[0]),
                                         .tx_done     (tx_done),
                                         .string      (string),
                                         .string_len  (string_len),
                                         .char        (char),
                                         .tx_signal   (tx_signal) );

    uart_frame_tx tx_inst ( .clk        (clk),
                            .reset_p    (reset_p),
                            .frame_en   (tx_signal),
                            .data_frame (char),
                            .tx_done    (tx_done),
                            .uart_tx    (uart_tx) );
endmodule

module servo_test(
    input clk,
    input reset_p,
    input [3:0] btn,
    output [7:0] led_bar,
    output servo_pwm
);

    btn_double_long  btn_servo_cntr(.clk     (clk), 
                                    .reset_p (reset_p), 
                                    .btn     (btn[0]),
                                    .single  (btn_single), 
                                    .double  (btn_double), 
                                    .long    (btn_long)    );    

    servo_rotation serv(clk, reset_p, btn_single, btn_double, btn_long, led_bar, servo_pwm);

    
endmodule


module clap_test (
    input clk,
    input reset_p,
    input clap,
    output reg single_var,
    output reg double_var
);

    clap_controller clap_inst(.clk     (clk),
                              .reset_p (reset_p),
                              .clap    (clap),
                              .single  (single),
                              .double  (double) );

    T_flip_flop_p toggle(clk, reset_p, single, toggle_xy);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            single_var <= 0;
            double_var <= 0;
        end
        else begin
            if (single) begin
                single_var <= ~single_var;
            end
            else if (double) begin
                double_var <= ~double_var;
            end
        end
    end
endmodule