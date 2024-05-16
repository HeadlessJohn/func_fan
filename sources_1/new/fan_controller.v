

module fan_controller #(SYS_FREQ = 125, N = 12) (
    input clk, reset_p,
    input btn,              // 버튼 입력
    input btn_back,         // 뒤로가기 버튼 입력
    input fan_en,           // 팬 동작 enable 신호
    input set_idle,         // IDLE 상태로 이동
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
            if ( (fan_en == 1) && (set_idle == 0) ) begin // fan_en이 활성화 되었을 때만 동작
                if (btn) begin
                    next_state <= {state[6:0], state[7]}; // state를 1비트씩 shift하여 다음 state로 이동
                end 
                if (btn_back) begin
                    next_state <= {state[0], state[7:1]}; // state를 1비트씩 shift하여 이전 state로 이동
                end
            end
            else begin // fan_en이 0인 경우 or set_idle이 1인 경우 IDLE 상태로 이동- fan 멈춤
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
                    run_e = 1;
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
