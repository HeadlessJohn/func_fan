`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


//박수 디바운싱 80ms
module clap_controller #(
    parameter CLAP_TO_CLAP_TIME  = 500_000, // 500ms
              DEBOUNCE_TIME      = 80_000   // 80ms
)(
    input clk, reset_p,
    input clap,
    output reg single,
    output reg double  );
    
    localparam WAIT_FOR_FIRST_CLAP         = 8'b0000_0001 ,
               DEBOUNCE_FIRST              = 8'b0000_0010 ,
               DEBOUNCE_SECOND             = 8'b0000_0100 ,
               WAIT_FOR_SECOND_CLAP        = 8'b0000_1000 ,
               SINGLE_CLAP_OUT             = 8'b0001_0000 ,
               DOUBLE_CLAP_OUT             = 8'b0010_0000 ;
    
    edge_detector_n ed_clap ( .clk(clk), .reset_p(reset_p), .cp(clap), .p_edge(clap_p) );

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
            state <= WAIT_FOR_FIRST_CLAP;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_us_e <= 0;
            single <= 0;
            double <= 0;
            next_state <= WAIT_FOR_FIRST_CLAP;
        end
        else begin
            case (state) 
                WAIT_FOR_FIRST_CLAP : begin
                    if (clap_p) begin                  // 첫번째 박수 감지 
                        next_state <= DEBOUNCE_FIRST; // 박수 디바운싱
                    end
                    else begin
                        single <= 0;
                        double <= 0;
                    end
                end

                DEBOUNCE_FIRST : begin
                    if (cnt_us < DEBOUNCE_TIME) begin      // 80ms 동안 모든 신호 무시 -> 디바운싱
                        cnt_us_e <= 1;                     // 타이머 시작
                    end
                    else begin
                        cnt_us_e <= 0;                      // 카운터를 초기화 하고
                        next_state <= WAIT_FOR_SECOND_CLAP; // 50ms 이후 두번째 박수 기다림
                    end
                end

                WAIT_FOR_SECOND_CLAP : begin
                    if (cnt_us < CLAP_TO_CLAP_TIME) begin  // 500ms 이내에 들어오는 두번째 박수 감지
                        cnt_us_e <= 1;                     // 타이머 시작
                        if (clap_p) begin                    // 두번째 박수가 감지되면
                            cnt_us_e <= 0;                 // 카운터 초기화
                            next_state <= DEBOUNCE_SECOND; // 디바운싱 시작
                        end
                    end
                    else begin
                        cnt_us_e <= 0;                      // 카운터 초기화
                        next_state <= SINGLE_CLAP_OUT;      // 싱글 박수 출력
                    end
                end

                DEBOUNCE_SECOND : begin
                    if (cnt_us < DEBOUNCE_TIME) begin        // 50ms 동안 모든 신호 무시 ->디바운싱
                        cnt_us_e <= 1;                       // 타이머 시작
                    end
                    else begin
                        cnt_us_e <= 0;                 // 카운터를 초기화 하고
                        next_state <= DOUBLE_CLAP_OUT; // 50ms 이후 더블 박수 출력
                    end
                end

                SINGLE_CLAP_OUT : begin
                    single <= 1;
                    next_state <= WAIT_FOR_FIRST_CLAP;
                end

                DOUBLE_CLAP_OUT : begin
                    double <= 1;
                    next_state <= WAIT_FOR_FIRST_CLAP;
                end
            endcase
        end
    end


endmodule