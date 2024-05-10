`timescale 1ns / 1ps
/*
module dht11  (input clk,
               input reset_p,
               inout dht11_data,         //input, inout은 reg 선언 불가능
               output reg[7:0] humidity, temperature,
               output [5:0] led_bar);

    // FSM 설계
    // 0~1~2~3~4~5 로 하면 덧셈기가 필요
    // bit shift를 이용하면 시프트 레지스터로 회로 생성
    // ERROR 발생시 IDLE로
    // DHT11의 측정 딜레이 3초
    // IDLE에서 3초이상 대기 후 다시 측정
    parameter S_IDLE      = 6'b00_0001;
    parameter S_LOW_18MS  = 6'b00_0010;
    parameter S_HIGH_20US = 6'b00_0100;
    parameter S_LOW_80US  = 6'b00_1000;
    parameter S_HIGH_80US = 6'b01_0000;
    parameter S_READ_DATA = 6'b10_0000;

    //READ_DATA 서브 상태
    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;

    //us단위로 3초를 세기위한 카운터
    reg [25:0] count_usec;
    wire clk_usec;
    clock_usec clk_us (clk, reset_p, clk_usec);

    reg count_usec_e;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) count_usec = 0;
        else begin
        // if (count_usec_e) begin
        //  if (clk_usec) count_usec = count_usec + 1;
        // end
        // else count_usec = 0;
            if (count_usec_e&&clk_usec)begin
                count_usec = count_usec + 1;
            end
            if (!count_usec_e) count_usec = 0;
        end
    end

    wire dht_pedge, dht_nedge;
    edge_detector_n ed0(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge));
    
    reg [5:0] state, next_state;
    reg [1:0] read_state;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) begin
            state = S_IDLE;
        end
        else state = next_state;
    end

    assign led_bar = state;

    reg [39:0] temp_data;
    reg [5:0] data_count;
    reg dht11_buffer;

    assign dht11_data = dht11_buffer; //데이터 출력 wire

    // FSM 상태천이
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            data_count   = 0;
            count_usec   = 0;
            read_state   = S_WAIT_PEDGE;
            next_state   = S_IDLE;
            dht11_buffer = 1'bz; // 초기화시 high-z 상태
            //inout은 출력하지 않을 경우 반드시 z상태로 만들어 주어야 함
        end
        else begin
            case(state)
                S_IDLE : begin
                    if (count_usec < 25'd3_000_000) begin // 3초 대기
                        count_usec_e = 1; // usec 카운터 시작
                        dht11_buffer = 1'bz; // 데이터 출력 Z상태
                    end
                    else begin
                        count_usec_e = 0; // 카운터 클리어
                        next_state   = S_LOW_18MS; // 다음 상태
                    end
                end
                S_LOW_18MS : begin
                    if (count_usec < 25'd0_020_000) begin
                        count_usec_e = 1;
                        dht11_buffer = 1'b0; // LOW 상태 18ms이상 유지
                    end
                    else begin
                        dht11_buffer = 1'bz; // 완료시 z상태
                        count_usec_e = 0; // 카운터 클리어
                        next_state   = S_HIGH_20US; // 다음 상태
                    end
                end
                S_HIGH_20US : begin
                    if (dht_nedge) begin //nedge를 기다림
                        next_state   = S_LOW_80US; // 다음 상태
                        count_usec_e = 0; //카운터 클리어
                    end
                end
                S_LOW_80US : begin
                    if (dht_pedge) begin// dht가 보내는 pedge검출시
                        next_state = S_HIGH_80US; // 다음 상태
                    end
                end
                S_HIGH_80US : begin
                    if (dht_nedge) begin // dht가 보내는 nedge검출시
                        next_state = S_READ_DATA; // 다음 상태
                    end
                end
                S_READ_DATA : begin //데이터 받기 상태
                    // receive data
                    case(read_state)
                        S_WAIT_PEDGE : begin
                            count_usec_e = 0;
                            if (dht_pedge) begin // pedge 검출시
                                read_state = S_WAIT_NEDGE; // 다음 상태
                            end
                        end
                        S_WAIT_NEDGE : begin
                            if (dht_nedge) begin // nedge 검출시
                                temp_data  = count_usec<50 ? {temp_data[38:0], 1'b0} : {temp_data[38:0], 1'b1};
                                data_count = data_count + 1;
                                read_state = S_WAIT_PEDGE; // 다음 비트 입력 대기 상태로
                            end
                            else begin // nedge가 오기 전까지
                                count_usec_e = 1; //카운터 시작. 시간측정
                            end
                        end
                    endcase
                    if (data_count >= 40) begin
                        data_count  = 0;
                        next_state  = S_IDLE;
                        humidity    = temp_data[39:32];
                        temperature = temp_data[23:16];
                    end
                end
                default : next_state = S_IDLE; // idle
            endcase
        end
    end
endmodule

*/

module dht11(
    input clk, reset_p,
    inout dht11_data,   //InOut Input도되고 Output도 되고
    output reg [7:0] humidity, temperature,
    output [7:0] led_bar);

    parameter S_IDLE        = 6'b000001;
    parameter S_LOW_18MS    = 6'b000010;
    parameter S_HIGH_20US   = 6'b000100;
    parameter S_LOW_80US    = 6'b001000;
    parameter S_HIGH_80US   = 6'b010000;
    parameter S_READ_DATA   = 6'b100000;

    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;

    reg [21:0] count_usec;
    wire clk_usec;
    reg count_usec_e;
    clock_usec usec_clk(clk, reset_p, clk_usec);

    //negedge써야 동작
    //posedge쓰면 1클록 뒤지게 되어 count 초기화 안되어 문제발생
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;
        end
    end

    wire dht_pedge, dht_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data),
        .p_edge(dht_pedge), .n_edge(dht_nedge));

    reg [5:0] state, next_state;
    reg [1:0] read_state;
    assign led_bar[5:0] = state;

    always @(negedge clk, posedge reset_p) begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end

    reg [39:0] temp_data; //temporally
    reg [5:0] data_count;
    reg dht11_buffer;
    assign dht11_data = dht11_buffer;

    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            count_usec_e = 0;
            next_state = S_IDLE;
            dht11_buffer = 1'bz; //임피던스 상태 , pullup저항때문에 데이터선이 HIGH가 됨
            //InOut은 반드시 임피던스상태를 줘야함
            read_state = S_WAIT_PEDGE;
            data_count = 0;
        end
        else begin
            case(state)

                S_IDLE : begin
                    if(count_usec <= 22'd3_000_000) begin //3_000_000 3초가 지나지 않으면
                        count_usec_e = 1;   //usec count가 계속 증가
                        dht11_buffer = 1'bz; //1로 유지되야 하지만
                        // 회로가 pullup이기 때문에 임피던스출력으로 끊어주면 알아서 1이된다
                    end
                    else begin  //3초가 지나면
                        next_state = S_LOW_18MS; //다음상태 LOW18ms로 넘어가고
                        count_usec_e = 0;   //usec count를 0으로 초기화
                    end
                end

                S_LOW_18MS : begin
                    if(count_usec <= 22'd20_000) begin //(최소18ms) 20ms가 지나지 않으면
                        count_usec_e = 1;
                        dht11_buffer = 0;   //LOW(0)
                    end
                    else begin
                        count_usec_e = 0;
                        next_state = S_HIGH_20US;
                        dht11_buffer = 1'bz;    //계속 읽어야하기때문에 임피던스출력으로 연결끊어줌
                    end
                end

                S_HIGH_20US : begin
                    if(dht_nedge) begin  //센서에서 보낸 신호가 negedge가 들어오면
                        next_state = S_LOW_80US; //다음상태로 넘어가고
                        count_usec_e = 0; //usec count초기화
                    end
                    else begin                     //nedge를 기다림
                        count_usec_e = 1;          //카운터 활성화
                        if (count_usec > 20) begin //20us 이상 대기시 S_IDLE로 
                            count_usec_e = 0;      //카운터 초기화
                            next_state = S_IDLE; 
                        end
                    end
                end

                S_LOW_80US : begin //센서가 전송해주는 신호 읽는 시간
                    if(dht_pedge) begin  //센서에서 보낸 신호가 pegedge가 들어오면
                        next_state = S_HIGH_80US; //다음상태로 넘어가고
                        count_usec_e = 0; //usec count초기화
                    end
                    else begin 
                        count_usec_e = 1;           //카운터 활성화
                        if (count_usec > 100) begin //100us 이상 대기시 S_IDLE로 
                            count_usec_e = 0;       //카운터 초기화
                            next_state = S_IDLE; 
                        end
                    end
                end

                S_HIGH_80US : begin//센서가 전송해주는 신호 읽는 시간
                    if(dht_nedge) begin  //센서에서 보낸 신호가 negedge가 들어오면
                        next_state = S_READ_DATA; //다음상태로 넘어가고
                        count_usec_e = 0; //usec count초기화
                    end
                    else begin 
                        count_usec_e = 1;           //카운터 활성화
                        if (count_usec > 100) begin //100us 이상 대기시 S_IDLE로 
                            count_usec_e = 0;       //카운터 초기화
                            next_state = S_IDLE; 
                        end
                    end
                end

                S_READ_DATA : begin
                    case (read_state)
                        // 데이터 보내기 전  50us low level 대기
                        S_WAIT_PEDGE : begin //센서 신호의 pedge를 기다리는 시간
                            if(dht_pedge) begin   //pedge가 들어 오면
                                count_usec_e = 0;
                                read_state = S_WAIT_NEDGE; //다음상태로 넘어가고
                            end
                            else begin
                                count_usec_e = 1;
                                if (count_usec > 60) begin //60us 이상 지연되면 S_IDLE상태로
                                    count_usec_e = 0;
                                    next_state = S_IDLE;
                                end
                            end
                        end

                        S_WAIT_NEDGE : begin//센서 신호의 nedge를 기다리면서 데이터들을 읽는 시간
                            if (dht_nedge) begin //nedge가 들어 오면
                                if (count_usec < 50) begin //기다린 시간이 50us 미만이면 0으로 판단
                                    temp_data = {temp_data[38:0], 1'b0}; //최상위 비트 버리고 최하위에 0
                                end
                                else if (count_usec < 100)begin //50~100us 이면 1로 판단
                                    temp_data = {temp_data[38:0], 1'b1}; //최하위비트에 1
                                end
                                else begin //100us 이상 대기시 초기화 후 IDLE
                                    temp_data = 40'b0;
                                    next_state = S_IDLE;
                                end
                                count_usec_e = 0;
                                data_count = data_count + 1; //데이터 하나 읽었습니다 표시
                                read_state = S_WAIT_PEDGE;
                            end
                            else begin  //nedge가 들어오기 전까지는
                                count_usec_e = 1; //시간을 카운트 하고
                            end
                        end
                    endcase

                    if (data_count >= 40) begin //데이터 40개 다 세면
                        data_count = 0; //세는count 0으로 초기화하고
                        next_state = S_IDLE; //다음상태는 IDLE상태
                        humidity = temp_data[39:32];//tempdata의 최상위 8비트가 습도
                        temperature = temp_data[23:16];//23:16의 8비트가 온도
                    end
                end
                default : next_state = S_IDLE;
            endcase
        end
    end
endmodule
// 가장 기본적인 회로를 만든 후 에러 상황에 대한 코드를 작성 하는 것이 디버깅에 도움됨
// 한번에 작성하면 경우의 수가 늘어나 디버깅이 쉽지 않음


module dht11_top (
    input clk, reset_p,
    inout dht11_data,
    output [5:0] led_bar,
    output [3:0] com,
    output [7:0] seg_7 );
    wire [7:0] humidity, temperature;
    dht11 dht(  .clk        (clk),
                .reset_p    (reset_p),
                .dht11_data (dht11_data),
                .humidity   (humidity),
                .temperature(temperature),
                .led_bar    (led_bar) );

    wire [15:0] bcd_humi, bcd_tmpr;
    bin_to_dec humi(.bin({4'b0000,humidity}),
                    .bcd(bcd_humi)          );
    bin_to_dec tmpr(.bin({4'b0000,temperature}),
                    .bcd(bcd_tmpr)          );

    wire [15:0] value;
    assign value = {bcd_humi[7:0], bcd_tmpr[7:0] };
    fnd_4_digit_cntr fnd(.clk             (clk),
                         .reset_p         (reset_p),
                         .value           (value),
                         .segment_data_ca (seg_7),
                         .com_sel         (com)      );
endmodule
