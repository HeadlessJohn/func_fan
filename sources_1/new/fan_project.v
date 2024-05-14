`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module project_1(
    input        clk, 
    input        reset_p,
    input  [2:0] btn,
    inout        dht11_data,

    output [7:0] led_bar, //for debug
    output       pwm, 
    output       led,
    output [3:0] com,     //for debug
    output [7:0] seg_7,   //for debug
    output       buz_clk,
    output       sda,
    output       scl    );

    localparam SYS_FREQ              = 125;      // 125MHz
    localparam BTN_HOLD_TIME         = 700_000;  // 700ms
    localparam BTN_DOUBLE_TAP_TIME   = 100_000;  // 100ms
    
    wire        fan_en, run_e;
    wire [7:0]  fan_led, timer_led;
    wire [19:0] cur_time;
    wire [7:0]  fan_speed;
    wire [3:0]  fan_timer_state;

    assign      fan_en = timeout_pedge ? 0 : 1;
    assign      led_bar = {fan_led[4:1], timer_led[3:0]};

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
    
    wire [1:0] btn_single, btn_double, btn_long;
    btn_double_long #(BTN_HOLD_TIME, BTN_DOUBLE_TAP_TIME) btn_fan_cntr (.clk     (clk), 
                                                                        .reset_p (reset_p), 
                                                                        .btn     (btn[0]),
                                                                        .single  (btn_single[0]), 
                                                                        .double  (btn_double[0]), 
                                                                        .long    (btn_long[0])    );
                  
    btn_double_long #(BTN_HOLD_TIME, BTN_DOUBLE_TAP_TIME) btn_led_cntr (.clk     (clk), 
                                                                        .reset_p (reset_p), 
                                                                        .btn     (btn[1]),
                                                                        .single  (btn_single[1]), 
                                                                        .double  (btn_double[1]), 
                                                                        .long    (btn_long[1])    );

    fan_controller #(SYS_FREQ, 12) (.clk      (clk), 
                                    .reset_p  (reset_p), 
                                    .btn      (btn_single[0]), 
                                    .btn_back (btn_double[0]),
                                    .set_idle (btn_long[0]),
                                    .fan_en   (fan_en), 
                                    .state    (fan_speed), 
                                    .pwm      (pwm), 
                                    .run_e    (run_e));

    led_controller led_cntr(clk, reset_p, btn_single[1], btn_long[1], led);
    
    fan_timer fan_tmr(clk, reset_p, btn[2], run_e, alarm, fan_timer_state, timeout_pedge, cur_time, timer_led);

    buz_top buzz(.clk (clk), .reset_p (reset_p), .buz_on (buz_on), .buz_clk (buz_clk));
   
    
    fnd_4_digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(cur_time[15:0]), .segment_data_ca(seg_7), .com_sel(com));
    
endmodule
