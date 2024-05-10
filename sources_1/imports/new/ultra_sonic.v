`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////



module ultra_sonic(
    input clk, reset_p,
    input echo,
    output reg trig,
    output [11:0] distance,
    output [7:0] led_bar    );

    parameter S_IDLE      = 4'b0001;
    parameter S_TRIG      = 4'b0010;
    parameter S_WAIT_ECHO_PEDGE = 4'b0100;
    parameter S_WAIT_ECHO_NEDGE = 4'b1000;

    //state 변경
    reg [3:0]state, next_state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            state = S_IDLE;
        end
        else begin
            state = next_state;
        end
    end
    
    //시간 측정용 타이머
    wire clk_usec;
    clock_usec clk_us0(clk, reset_p, clk_usec);
    
    //edge detect
    wire echo_p, echo_n;
    edge_detector_n ed0(clk, reset_p, echo, echo_p, echo_n);

    reg count_usec_e;
    reg [20:0] count_usec;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;
        end
    end


    //state 처리
    reg cnt_e;
    sr04_cnt58 dis_cnt(clk, reset_p, clk_usec, cnt_e, distance);

    always @(posedge clk, posedge reset_p) begin 
    // clk -> clk_usec 으로 바꾸면 required time이 1us로 늘어남
    // always문을 모두 같은 클럭을 사용하지 않게 되므로 비동기 회로임
    // 모두 clk_usec으로 사용하거나 모두 clk로 사용해야 함
        if (reset_p) begin
            next_state <= S_IDLE;
            cnt_e <= 0;
            count_usec_e <= 0;
            trig <= 0;
        end
        else begin
            case (state) 

                //200ms 마다 신호 발생
                S_IDLE : begin
                    if (count_usec < 200_000) begin
                        count_usec_e <= 1;
                    end
                    else begin
                        next_state <= S_TRIG;
                        count_usec_e <= 0;
                    end
                end

                //TRIG 10us 발사
                S_TRIG : begin
                    if (count_usec < 10) begin
                        count_usec_e <= 1;
                        trig <= 1'b1;
                    end
                    else begin
                        next_state <= S_WAIT_ECHO_PEDGE;
                        trig <= 1'b0;
                        count_usec_e <= 0;
                    end
                end

                S_WAIT_ECHO_PEDGE : begin
                    if (echo_p) begin 
                        next_state <= S_WAIT_ECHO_NEDGE;
                        count_usec_e <= 0;
                        cnt_e <= 1; // echo 시간 측정 시작
                    end
                    else begin
                        if (count_usec >= 10_000) begin // 10ms 이상 안들어오면
                            next_state <= S_IDLE;
                            count_usec_e <= 0;
                        end
                        else count_usec_e <= 1;
                    end
                end

                S_WAIT_ECHO_NEDGE : begin 
                    if (echo_n) begin
                        cnt_e <= 0;
                        count_usec_e <= 0;
                        next_state <= S_IDLE;
                    end
                    else begin
                        if (count_usec >= 20_000) begin // 20ms 이상 안들어오면
                            next_state <= S_IDLE;
                            count_usec_e <= 0;
                            cnt_e <= 0;
                        end             
                        else count_usec_e <= 1;           
                    end
                end
            endcase
        end
    end

    assign led_bar = {cnt_e, count_usec_e, 1'b0, 1'b0, state};
endmodule

module sr04_cnt58(
    input clk, reset_p,
    input clk_usec,
    input clk_e,
    output reg [11:0] distance);


    reg [6:0] cnt;
    reg [11:0] distance_cnt;
    always @(posedge reset_p, posedge clk) begin
        if(reset_p) begin
            cnt <= 0;
            distance <= 0;
            distance_cnt <= 0;
        end 
        else begin
            if (clk_e) begin
                if (clk_usec) begin
                    if (cnt >= 58) begin
                        cnt <= 0;
                        distance_cnt <= distance_cnt + 1;
                    end
                    else begin
                        cnt <= cnt + 1;
                    end
                end
            end 
            else begin
                distance <= distance_cnt;
                cnt <= 0;
            end
        end
    end
endmodule


module ultra_sonic_top (
    input clk, reset_p,
    input echo,
    output trig,
    output [7:0] seg_7,
    output [3:0] com,
    output [7:0] led_bar    );

    wire [11:0] distance;
    ultra_sonic us (clk, reset_p, echo, trig, distance, led_bar);

    // BCD 변환
    wire [15:0] value;
    bin_to_dec dis(.bin(distance),
                   .bcd(value)          );

    fnd_4_digit_cntr fnd(.clk(clk),
                         .reset_p(reset_p),
                         .value(value),
                         .segment_data_ca(seg_7),
                         .com_sel(com)             );
endmodule

// pdt가 있으므로 계산이 끝나기 전 그 값을 읽게 되면 잘못된 값이 읽혀짐
// 예를들어 pdt 4ns면 최소 4ns 이후에 읽어야 하고 4ns 이전에 잘못된 값을 읽는것을 막기 위해 뒤에 FF를 붙여 방지함
// 100MHz 라면 10ns주기 이므로 10ns 이후에 읽을 수 있음
// pdt 가 12ns라면 2ns 늦으므로 2클록이 지나야 제대로 읽을 수 있음 (negative slack)
// 입력이 바뀌고 출력이 나오기까지 걸리는 총 PDT = 도달시간 (arrival time)
// 요구시간 (required time) = 도달시간(arrival time) + 시간 여유 (slack time)