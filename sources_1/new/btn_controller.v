`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/14/2024 06:16:21 PM
// Design Name: 
// Module Name: btn_controller
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


module btn_long_press(
    input clk, reset_p,
    input btn,
    output [7:0]led_bar,
    output reg btn_short_out,
    output reg btn_long_out   );

    localparam WAIT_FOR_PEDGE    = 8'b0000_0001;
    localparam TIMER_RUNNING     = 8'b0000_0010;
    localparam SHORT_PRESS_OUT   = 8'b0000_0100;
    localparam LONG_PRESS_OUT    = 8'b0000_1000;
    localparam START_PRESS_TIMER = 8'b0001_0000;
    localparam TIMEOUT           = 8'b0010_0000;
    

    wire btn_p, btn_n;
    button_cntr btn0(.clk(clk),
                     .reset_p(reset_p), 
                     .btn(btn),
                     .btn_p_edge(btn_p),
                     .btn_n_edge(btn_n));

    wire clk_usec;
	clock_usec # (125) clk_us(clk, reset_p, clk_usec);

	// ms 카운터
	reg [20:0] cnt_us;
	reg cnt_us_e;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_us <= 20'b0;
		end
		else begin
			if (cnt_us_e) begin
				if (clk_usec) begin
					cnt_us <= cnt_us + 1;
				end
			end
			else begin
				cnt_us <= 20'b0;
			end
		end
	end

    reg [7:0] state, next_state;
    assign led_bar = state;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) begin
            state <= WAIT_FOR_PEDGE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_us_e <= 0;
            btn_short_out <= 0;
            btn_long_out <= 0;
            next_state <= WAIT_FOR_PEDGE;
        end
        else begin
            case (state)
                WAIT_FOR_PEDGE : begin
                    btn_short_out <= 0;
                    btn_long_out <= 0;
                    if (btn_p) begin // positive edge가 검출되면 타이머 시작
                        cnt_us_e <= 1; // 카운터 활성화
                        next_state <= TIMER_RUNNING;
                    end
                end

                TIMER_RUNNING : begin
                    if (cnt_us < 500_000) begin // 500ms
                        if (btn_n) begin // 시간 내에 negative edge가 검출되면 숏프레스로 판단
                            cnt_us_e <= 0;   //카운터를 초기화하고
                            next_state <= SHORT_PRESS_OUT; // 숏프레스 출력
                        end
                    end
                    else begin // 500ms가 지나도록 negative edge가 검출되지 않으면 롱프레스로 판단
                        cnt_us_e <= 0; // 카운터를 초기화하고
                        next_state <= LONG_PRESS_OUT; // 롱프레스 출력
                    end
                end

                SHORT_PRESS_OUT : begin
                    btn_short_out <= 1;
                    next_state <= WAIT_FOR_PEDGE;
                end

                LONG_PRESS_OUT : begin
                    btn_long_out <= 1;
                    next_state <= WAIT_FOR_PEDGE;
                end

            endcase
        end
    end

endmodule

module btn_double_long #(
    parameter HOLD_TIME = 700_000, // 700ms
    parameter DOUBLE_TIME = 100_000 // 100ms
)(
    input clk, reset_p,
    input btn,
    output reg single,
    output reg double,
    output reg long );
    
    localparam WAIT_FOR_PEDGE         = 8'b0000_0001;
    localparam TIMER_RUNNING          = 8'b0000_0010;
    localparam WAIT_FOR_SECOND_PEDGE  = 8'b0000_0100;
    localparam SHORT_PRESS_OUT        = 8'b0000_1000;
    localparam LONG_PRESS_OUT         = 8'b0001_0000;
    localparam DOUBLE_TAP_OUT         = 8'b0010_0000;
    

    wire btn_p, btn_n;
    button_cntr btn0(.clk(clk),
                     .reset_p(reset_p), 
                     .btn(btn),
                     .btn_p_edge(btn_p),
                     .btn_n_edge(btn_n));

    wire clk_usec;
	clock_usec # (125) clk_us(clk, reset_p, clk_usec);

	// ms 카운터
	reg [20:0] cnt_us;
	reg cnt_us_e;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_us <= 20'b0;
		end
		else begin
			if (cnt_us_e) begin
				if (clk_usec) begin
					cnt_us <= cnt_us + 1;
				end
			end
			else begin
				cnt_us <= 20'b0;
			end
		end
	end

    reg [7:0] state, next_state;
    assign led_bar = state;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) begin
            state <= WAIT_FOR_PEDGE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_us_e <= 0;
            single <= 0;
            long <= 0;
            double <= 0;
            next_state <= WAIT_FOR_PEDGE;
        end
        else begin
            case (state)
                WAIT_FOR_PEDGE : begin
                    single <= 0;
                    long <= 0;
                    double <= 0;
                    if(btn_p)begin
                        cnt_us_e <= 1;
                        next_state <= TIMER_RUNNING;
                    end
                end

                TIMER_RUNNING : begin
                    if (cnt_us < HOLD_TIME) begin                // 700ms
                        if (btn_n) begin                         // 시간 내에 negative edge가 검출되면 싱글or더블로 판단
                            cnt_us_e <= 0;                       //카운터를 초기화하고
                            next_state <= WAIT_FOR_SECOND_PEDGE; // 싱글탭or더블탭 판단으로 이동
                        end
                    end
                    else begin                                   // 500ms가 지나도록 negative edge가 검출되지 않으면 롱프레스로 판단
                        cnt_us_e <= 0;                           // 카운터를 초기화하고
                        next_state <= LONG_PRESS_OUT;            // 롱프레스 출력
                    end
                end
                
                WAIT_FOR_SECOND_PEDGE : begin 
                    if (cnt_us < DOUBLE_TIME) begin             // 100ms동안 새로운 입력을 기다림
                        cnt_us_e <= 1;                          // 카운터를 활성화
                        if(btn_p) begin                         // 300ms 동안 새로운 positive edge 검출시
                            cnt_us_e <= 0;                      // 카운터를 초기화하고
                            next_state <= DOUBLE_TAP_OUT;       // 더블탭으로 판단
                        end
                    end
                    else begin                                  // 100ms가 지나도록 새로운 입력이 들어오지 않으면
                        cnt_us_e <= 0;                          // 카운터를 초기화하고
                        next_state <= SHORT_PRESS_OUT;          // 싱글탭으로 판단
                    end
                end

                SHORT_PRESS_OUT : begin
                    single <= 1;
                    next_state <= WAIT_FOR_PEDGE;
                end

                LONG_PRESS_OUT : begin
                    long <= 1;
                    next_state <= WAIT_FOR_PEDGE;
                end

                DOUBLE_TAP_OUT : begin
                    double <= 1;
                    next_state <= WAIT_FOR_PEDGE;
                end

            endcase

        end
    end

endmodule