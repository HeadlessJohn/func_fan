`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module servo_rotation #(
    parameter SYS_FREQ = 125,
    parameter N = 12
) (
    input clk, reset_p,
    input start_stop,
    input rot_toggle,
    input btn_long,
    input rot_en,
    output [7:0]duty_out,
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

    wire clk_usec, clk_msec, clk_Nmsec;
    clock_usec #(SYS_FREQ) usec(clk, reset_p, clk_usec);
    clock_div_1000 msec(clk, reset_p, clk_usec, clk_msec);
    clock_div_N #(4) Nmsec(clk, reset_p, clk_msec, clk_Nmsec);

    reg [N-1:0] pwm_duty;
    reg dir_toggle;
    reg on_off;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin 
            pwm_duty <= deg_90_a;
            dir_toggle <= 1'b1; // 왼쪽 먼저
            on_off <= 1'b0;
        end
        else begin
            if (start_stop) begin // 누를때마다 ON/OFF
                on_off = ~on_off;
            end
            else if (rot_toggle) begin // 더블탭 하면 강제 방향전환
                dir_toggle = ~dir_toggle;
            end
            else begin
                if (on_off && rot_en) begin
                    if (clk_Nmsec) begin //toggle 1이면 왼쪽 0이면 오른쪽
                        pwm_duty = ( dir_toggle ? pwm_duty + 1 : pwm_duty - 1 );
                        if (pwm_duty <= deg_180_a) dir_toggle = ~dir_toggle;
                        else if (pwm_duty >= deg_0_a) dir_toggle = ~dir_toggle;
                    end
                end
            end
        end
    end

    assign duty_out = pwm_duty[7:0];
    pwm_controller #(SYS_FREQ, N) pwm_motor(.clk      (clk), 
                                            .reset_p  (reset_p), 
                                            .duty     (pwm_duty),
                                            .pwm_freq (50), 
                                            .pwm      (motor_pwm)          );
endmodule