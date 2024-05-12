`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2024 01:33:43 AM
// Design Name: 
// Module Name: i2c_lcd
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


/*
HD44780 - LCD Controller

RS (Register Select) : 레지스터를 선택하는 DEMUX 신호
RS: 0 -> 명령어 레지스터에 작성
RS: 1 -> 데이터 레지스터에 작성

R/W^ : 읽기/쓰기 선택 신호
R/W^: 0 -> 읽기, 1 -> 쓰기

EN 이 1이 되어야 레지스터에 데이터가 쓰여짐 (Level trigger)
데이터를 보낸 후 EN을 1 주어야함

32칸 x 2줄 메모리 블럭이 존재

화면은 16x2 로 출력됨

폰트 데이터는 내부에 이미 저장되어 있음

0011_0001 을 입력하면 숫자 1을 출력함 -> ASCII코드와 동일

Clear Display : 화면 초기화
Return Home : 커서를 홈으로 이동
Entry Mode Set : 커서의 이동 방향 설정
				- S : 1이면 커서 이동시 화면이 이동
	            - I/D : 커서 이동 방향 설정 (1이면 오른쪽으로 이동)
Display On/Off Control : 화면 표시 설정
				- D : 1이면 화면 표시
				- C : 1이면 커서 표시
				- B : 1이면 커서 깜박임


*/

/*
I2C

CLK가 LOW일때 데이터를 바꾸고 HIGH일때 읽는다

CLK가 HIGH일때 falling edge -> start bit
CLK가 HIGH일때 rising edge -> stop bit
MSB부터 전송 (최상위)
ACK : slave가 보내는 응답신호. 0이면 데이터를 받았다는 의미

		shift register
	  [ | | | | | | | ]

		->  ->  shift
SDA-  [7|6|5|4|3|2|1|0]  LSB부터 8개의 데이터가 들어옴
SCL-  clock 

 D7 |D6 |D5 |D4 |BT |EN |RW | RS
[ 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 ]

PC8574의 ADRESS : 0x27<<1 = 0x4E

*/

module i2c_master (
	input clk, reset_p,
	input rw,   //읽기/쓰기 선택 R:1  W:0
	input [6:0] addr, //slave 주소
	input [7:0] data_in, //입력 데이터
	input valid, //시작 신호
	output reg sda,
	output reg scl );

	localparam S_IDLE      		 = 7'b000_0001;
	localparam S_COMM_START		 = 7'b000_0010;
	localparam S_SEND_ADDR 		 = 7'b000_0100;
	localparam S_RD_ACK    		 = 7'b000_1000;
	localparam S_SEND_DATA 		 = 7'b001_0000;
	localparam S_SCL_STOP  		 = 7'b010_0000;
	localparam S_COMM_STOP 		 = 7'b100_0000;

	//주소와 r/w 신호 합치기
	wire [7:0] addr_rw;
	assign addr_rw = {addr, rw};

	// scl 클록 
	wire clock_usec;
	clock_usec # (125) clk_us(clk, reset_p, clock_usec);

	//5us마다 scl 토글하여 10us 주기로 scl 생성
	reg [2:0] cnt_usec_5;
	reg scl_toggle_e;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_usec_5 = 3'b000;
			scl = 1'b1;
		end
		else begin
			if (scl_toggle_e) begin
				if (clock_usec) begin
					if(cnt_usec_5 >= 4) begin
						cnt_usec_5 = 0;
						scl = ~scl;
					end
					else begin
						cnt_usec_5 = cnt_usec_5 + 1;
					end
				end
			end
			else begin // scl_toggle_e == 0 일때 카운터 초기화, scl 1로 설정
				cnt_usec_5 = 3'b000;
				scl = 1'b1;
			end
		end
	end

	// 시작 신호 edge detector
	wire valid_p;
	edge_detector_n edge_valid(clk, reset_p, valid, valid_p);

	//scl edge detector
	wire scl_p, scl_n;
	edge_detector_n edge_scl(clk, reset_p, scl, scl_p, scl_n);

	// finite state machine
	// negedge 에서 상태 바꿈 주의
	reg [6:0] state, next_state;
	always @(negedge clk, posedge reset_p)begin
		if(reset_p) begin
			state <= S_IDLE;
		end else 
		begin
			state <= next_state;
		end
	end

	reg [7:0] data_out;
	reg [2:0] d_out_cnt;
	reg send_data_done_flag;
	reg [2:0] cnt_stop;
	always @(posedge clk or posedge reset_p)begin
		if(reset_p) begin
			sda <= 1'b1;
			next_state <= S_IDLE;
			scl_toggle_e <= 1'b0;
			d_out_cnt <= 7;
			send_data_done_flag <= 1'b0;
			cnt_stop <= 0;
		end else 
		begin
			if (1) begin
				case (state)
					S_IDLE : begin 
						if(valid_p) begin //외부에서 신호를 받으면 IDLE상태에서 START로 전환
							next_state <= S_COMM_START;
						end
						else begin // IDLE 상태로 대기
							next_state <= S_IDLE;
							d_out_cnt <= 7;
						end
					end

					S_COMM_START : begin
						sda <= 1'b0; //start bit를 전송
						scl_toggle_e <= 1'b1; // scl 토글 시작 
						next_state <= S_SEND_ADDR; // 다음 상태로
					end

					S_SEND_ADDR : begin // 최상위비트부터 전송 시작
						if(scl_n) sda = addr_rw[d_out_cnt];
						else if (scl_p) begin
							if (d_out_cnt == 0) begin
								d_out_cnt <= 7;
								next_state <= S_RD_ACK;
							end
							else d_out_cnt <= d_out_cnt - 1;
						end
					end
					
					S_RD_ACK : begin
						if(scl_n) begin 
							sda <= 'bz; // Z상태로 ACK을 기다림
						end
						else if(scl_p) begin
							if(send_data_done_flag) begin // 데이터 전송이 끝난 경우 주소전송인지 데이터인지 판단하여 다음상태 전환 
								next_state <= S_SCL_STOP; 
							end
							else begin
								next_state <= S_SEND_DATA;
							end
							send_data_done_flag <= 0;
						end
					end

					S_SEND_DATA : begin // 최상위비트부터 전송 시작
						if(scl_n) sda <= data_in[d_out_cnt];
						else if (scl_p) begin
							if (d_out_cnt == 0) begin
								d_out_cnt <= 7;
								next_state <= S_RD_ACK;
								send_data_done_flag <= 1;
							end
							else d_out_cnt <= d_out_cnt - 1;
						end
					end

					S_SCL_STOP : begin
						if (scl_n) begin
							sda <= 1'b0;
						end
						else if (scl_p) begin
							scl_toggle_e <= 1'b0; // scl 토글 중지
							next_state <= S_COMM_STOP;
						end
					end

					S_COMM_STOP : begin
						if(clock_usec) begin
							cnt_stop <= cnt_stop + 1;
							if(cnt_stop >= 3) begin
								sda <= 1'b1;
								cnt_stop <= 0;
								next_state <= S_IDLE;
							end
						end
					end
				endcase
			end
		end
	end

endmodule

module i2c_transmit_addr_byte (
	input clk, reset_p,
	input [6:0] addr, //slave 주소
	input rs, // 명령어/데이터 선택 0: 명령어, 1: 데이터
	input [7:0] data_in, //입력 데이터
	input valid, //시작 신호
	output reg sda,
	output reg scl );

	localparam S_IDLE      		 = 7'b000_0001;
	localparam S_COMM_START		 = 7'b000_0010;
	localparam S_SEND_ADDR 		 = 7'b000_0100;	
	localparam S_RD_ACK    		 = 7'b000_1000;
	localparam S_SEND_DATA 		 = 7'b001_0000;
	localparam S_SCL_STOP  		 = 7'b010_0000;
	localparam S_COMM_STOP 		 = 7'b100_0000;

	// addr + rw 합치기  rw : 0 쓰기, 1 읽기
	wire [7:0] addr_rw;
	assign addr_rw = {addr, rs};

	// scl 클록 
	wire clock_usec;
	clock_usec # (125) clk_us(clk, reset_p, clock_usec);

	//5us마다 scl 토글하여 10us 주기로 scl 생성
	reg [2:0] cnt_usec_5;
	reg scl_toggle_e;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_usec_5 = 3'b000;
			scl = 1'b1;
		end
		else begin
			if (scl_toggle_e) begin
				if (clock_usec) begin
					if(cnt_usec_5 >= 4) begin
						cnt_usec_5 = 0;
						scl = ~scl;
					end
					else begin
						cnt_usec_5 = cnt_usec_5 + 1;
					end
				end
			end
			else begin // scl_toggle_e == 0 일때 카운터 초기화, scl 1로 설정
				cnt_usec_5 = 3'b000;
				scl = 1'b1;
			end
		end
	end

	// 시작 신호 edge detector
	wire valid_p;
	edge_detector_n edge_valid(clk, reset_p, valid, valid_p);

	//scl edge detector
	wire scl_p, scl_n;
	edge_detector_n edge_scl(clk, reset_p, scl, scl_p, scl_n);

	// finite state machine
	// negedge 에서 상태 바꿈 주의
	reg [6:0] state, next_state;
	always @(negedge clk, posedge reset_p)begin
		if(reset_p) begin
			state <= S_IDLE;
		end else 
		begin
			state <= next_state;
		end
	end

	reg [2:0] d_out_cnt;
	reg [2:0] cnt_stop;
	reg data_tx_complete;
	always @(posedge clk or posedge reset_p)begin
		if(reset_p) begin
			sda <= 1'b1;
			next_state <= S_IDLE;
			scl_toggle_e <= 1'b0;
			d_out_cnt <= 7;
			data_tx_complete <= 0;
			cnt_stop <= 0;
		end else 
		begin
			case (state)
				S_IDLE : begin 
					if(valid_p) begin //외부에서 신호를 받으면 IDLE상태에서 START로 전환
						next_state <= S_COMM_START;
					end
					else begin // IDLE 상태로 대기
						next_state <= S_IDLE;
						d_out_cnt <= 7;
					end
				end

				S_COMM_START : begin
					sda <= 1'b0; //start bit를 전송
					scl_toggle_e <= 1'b1; // scl 토글 시작 
					next_state <= S_SEND_ADDR; // 다음 상태로
				end

				S_SEND_ADDR : begin // 최상위비트부터 전송 시작
					if(scl_n) sda <= addr_rw[d_out_cnt];
					else if (scl_p) begin
						if (d_out_cnt == 0) begin
							d_out_cnt <= 7;
							next_state <= S_RD_ACK;
						end
						else d_out_cnt <= d_out_cnt - 1;
					end
				end

				S_RD_ACK : begin
					if(scl_n) begin 
						sda <= 'bz; // Z상태로 ACK을 기다림
					end
					else if(scl_p) begin
						if (data_tx_complete) begin
							next_state <= S_SCL_STOP; 
							data_tx_complete <= 0;
						end
						else begin
							next_state <= S_SEND_DATA;
						end
					end
				end

				S_SEND_DATA : begin // 최상위비트부터 전송 시작
					if(scl_n) sda <= data_in[d_out_cnt];
					else if (scl_p) begin
						if (d_out_cnt == 0) begin
							d_out_cnt <= 7;
							next_state <= S_RD_ACK;
							data_tx_complete <= 1;
						end
						else d_out_cnt <= d_out_cnt - 1;
					end
				end

				S_SCL_STOP : begin
					if (scl_n) begin
						sda <= 1'b0;
					end
					else if (scl_p) begin
						scl_toggle_e <= 1'b0; // scl 토글 중지
						next_state <= S_COMM_STOP;
					end
				end

				S_COMM_STOP : begin
					if(clock_usec) begin
						cnt_stop <= cnt_stop + 1;
						if(cnt_stop >= 3) begin
							sda <= 1'b1;
							cnt_stop <= 0;
							next_state <= S_IDLE;
						end
					end
				end
			endcase
		end
	end
endmodule


module i2c_lcd_4bit_mode_tx(
	input clk, reset_p,
	input [7:0] data_in,
	input [6:0] addr,
	input send, rs,
	input send_4bit,
	output reg busy_flag,    
	output scl, sda     );

	// RS : 0 -> 명령어 레지스터에 작성
	// RS : 1 -> 데이터 레지스터에 작성

	localparam S_IDLE				  	 = 6'b00_0001;
	localparam S_EN_CLEAR				 = 6'b00_0010;
	localparam S_HIGH_NIBBLE_READY  	 = 6'b00_0100;
	localparam S_HIGH_NIBBLE_ENABLE 	 = 6'b00_1000;
	localparam S_LOW_NIBBLE_READY    	 = 6'b01_0000;
	localparam S_LOW_NIBBLE_ENABLE 	     = 6'b10_0000;

	localparam BL_ON = 1'b1; // 백라이트 켜기
	localparam BL_OFF = 1'b0; // 백라이트 끄기
	localparam EN_0 = 1'b0; // enable 1
	localparam EN_1 = 1'b1; // enable 0
	localparam WRITE = 1'b0; // write
	localparam READ = 1'b1; // read
	localparam RS_CMD = 1'b0; // command
	localparam RS_DATA = 1'b1; // data

	wire send_e;
	edge_detector_n edge_send(clk, reset_p, send, send_e);

	reg valid;
	reg [7:0] send_buffer;
	i2c_master i2c( .clk(clk),
                    .reset_p(reset_p),
                    .rw(1'b0),              // 0 : write, 1 : read
                    .addr(addr),
                    .data_in(send_buffer),
                    .valid(valid),
                    .sda(sda),
                    .scl(scl) );


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

	// FSM
	reg [5:0]state, next_state;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= S_IDLE;
		end
		else begin
			state <= next_state;
		end
	end

	//  D7 |D6 |D5 |D4 |BT |EN |RW | RS
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			next_state <= S_IDLE;
			send_buffer <= 8'b0;
			cnt_us_e <= 0;
			valid <= 0;
			busy_flag <= 0;
		end
		else begin
			case (state)
				S_IDLE : begin
					if (send_e) begin
						busy_flag <= 1; //데이터 전송중 플래그
						if (send_4bit) next_state <= S_LOW_NIBBLE_READY;
						else next_state <= S_HIGH_NIBBLE_READY;
					end
					else begin
						next_state <= S_IDLE;
						send_buffer <= 8'b0;
						cnt_us_e <= 0;
						valid <= 0;
						busy_flag <= 0;
					end
				end

				// S_EN_CLEAR : begin
				// 	cnt_us_e <= 1; // 카운터를 활성화
				// 	if      (cnt_us < 100) send_buffer <= { data_in[7:4], BL_ON, EN_0, WRITE, rs}; // 100us동안 버퍼에 준비
				// 	else if (cnt_us < 200) valid <= 1'b1; // 100us 동안 EN 1
				// 	else if (cnt_us < 300) valid <= 1'b0; // 100us 동안 EN 0
				// 	else begin
				// 		cnt_us_e <= 0; // 카운터를 초기화 하고
				// 		next_state <= S_HIGH_NIBBLE_READY; // 다음상태로 이동
				// 	end 
				// end

				S_HIGH_NIBBLE_READY : begin
					cnt_us_e <= 1; // 카운터를 활성화
					if      (cnt_us < 100) send_buffer <= { data_in[7:4], BL_ON, EN_1, WRITE, rs}; // 100us동안 버퍼에 준비
					else if (cnt_us < 300) valid <= 1'b1; // 100us 동안 EN 1
					else if (cnt_us < 500) valid <= 1'b0; // 100us 동안 EN 0
					else begin
						cnt_us_e <= 0; // 카운터를 초기화 하고
						next_state <= S_HIGH_NIBBLE_ENABLE; // 다음상태로 이동
					end 
				end

				S_HIGH_NIBBLE_ENABLE : begin
					cnt_us_e <= 1; // 카운터를 활성화
					if      (cnt_us < 100) send_buffer <= { data_in[3:0], BL_ON, EN_0, WRITE, rs}; // 100us동안 버퍼에 준비
					else if (cnt_us < 300) valid <= 1'b1; // 100us 동안 EN 1
					else if (cnt_us < 500) valid <= 1'b0; // 100us 동안 EN 0
					else begin
						cnt_us_e <= 0; // 카운터를 초기화 하고
						next_state <= S_LOW_NIBBLE_READY; // 다음상태로 이동
					end 
				end

				S_LOW_NIBBLE_READY : begin
					cnt_us_e <= 1; // 카운터를 활성화
					if      (cnt_us < 100) send_buffer <= { data_in[3:0], BL_ON, EN_1, WRITE, rs}; // 100us동안 버퍼에 준비
					else if (cnt_us < 300) valid <= 1'b1; // 100us 동안 EN 1
					else if (cnt_us < 500) valid <= 1'b0; // 100us 동안 EN 0
					else begin
						cnt_us_e <= 0; // 카운터를 초기화 하고
						next_state <= S_LOW_NIBBLE_ENABLE; // 다음상태로 이동
					end 
				end

				S_LOW_NIBBLE_ENABLE : begin
					cnt_us_e <= 1; // 카운터를 활성화
					if      (cnt_us < 100) send_buffer <= { data_in[3:0], BL_ON, EN_0, WRITE, rs}; // 100us동안 버퍼에 준비
					else if (cnt_us < 300) valid <= 1'b1; // 100us 동안 EN 1
					else if (cnt_us < 500) valid <= 1'b0; // 100us 동안 EN 0
					else begin
						cnt_us_e <= 0; // 카운터를 초기화 하고
						next_state <= S_IDLE; // 다음상태로 이동
					end 
				end
			endcase
		end
	end

endmodule



module i2c_tx_data (
    input clk, reset_p,
    input [6:0] addr,
    input rs_in,          // 0: command, 1: data
    input [7:0] data,     // tx module로 보낼 데이터
    input send_data,      // tx module로 송신 on off
	output busy_flag,     // busy flag
    output scl, sda);

    localparam IDLE = 6'b00_0001;
    localparam WAIT = 6'b00_0010;
    localparam INIT = 6'b00_0100;
    // 초기화 세부상태
    localparam INIT_PROCEDURE_0  = 12'b0000_0000_0001; //0 3 3 3 2 2 8 0 c 0 1 0 6
    localparam INIT_PROCEDURE_1  = 12'b0000_0000_0010; //0 3 3 3 2 2 8 0 c 0 1 0 6
    localparam INIT_PROCEDURE_2  = 12'b0000_0000_0100;
    localparam INIT_PROCEDURE_3  = 12'b0000_0000_1000;
    localparam INIT_PROCEDURE_4  = 12'b0000_0001_0000;
    localparam INIT_PROCEDURE_5  = 12'b0000_0010_0000;
    localparam INIT_PROCEDURE_6  = 12'b0000_0100_0000;
    localparam INIT_PROCEDURE_7  = 12'b0000_1000_0000;
    localparam INIT_PROCEDURE_8  = 12'b0001_0000_0000;
    localparam INIT_PROCEDURE_9  = 12'b0010_0000_0000;
    localparam INIT_COMPLETE     = 12'b0100_0000_0000;

    localparam SEND = 6'b00_1000;
    localparam SEND2 = 6'b01_0000;

	                            // function set
                                // 001 + DL N F * *
                                // DL : 0이면 4bit, 1이면 8bit  <<4bit사용
                                // N : 0이면 1줄, 1이면 2줄    <<2줄 사용
                                // F : 0이면 5x8, 1이면 5x10   <<5x8 사용
    localparam FUNCTION_SET  = 8'b001_010_00;
	localparam DISPLAY_ON    = 8'b0000_1100;
    localparam DISPLAY_OFF   = 8'b0000_1000;
    localparam DISPLAY_CLR   = 8'b0000_0001;

                                // entry mode set
                                // 0000_01 + I/D S
                                // I/D : 0이면 커서 왼쪽으로, 1이면 오른쪽으로 증가
                                // S : 0이면 화면이 이동, 1이면 고정
    localparam ENTRYMODE_SET = 8'b0000_01_10;

    reg [7:0] send_buffer;
    reg send_e, rs;
    wire send_data_p;
    edge_detector_n ed_send_data(clk, reset_p, send_data, send_data_p);

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

	// FSM
	reg [5:0]state, next_state;
    reg [11:0] init_procedure, next_init_procedure;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= IDLE;
            init_procedure <= INIT_PROCEDURE_1;
		end
		else begin
			state <= next_state;
            init_procedure <= next_init_procedure;
		end
	end

    reg send_4bit;
    always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			next_state <= IDLE;
            next_init_procedure <= INIT_PROCEDURE_1;
            cnt_us_e <= 1'b0;
            send_buffer <= 8'b0;
            rs <= 1'b0;
            send_e <= 1'b0;
            send_4bit <= 1'b0; //1이면 4bit, 0이면 8bit
		end
		else begin
			case (state)
                IDLE : begin
                    if (init_procedure == INIT_COMPLETE) begin // 초기화가 완료되었다면 버튼입력을 허용
                        if(send_data_p) next_state <= SEND;
                        else begin
                            send_e <= 1'b0;
                        end
                    end
                    else next_state <= WAIT;
                end
                
                WAIT : begin // 40ms 대기하고
                    if (cnt_us <= 20'd40_000) begin
                            cnt_us_e <= 1'b1;
                        end
                    else begin // 40ms가 지나면 INIT 진행
                        next_state = INIT;
                        cnt_us_e <= 1'b0; //타이머를 초기화
                    end
                end
                /*
                 N : 0이면 1줄, 1이면 2줄
                 F : 0이면 5x8, 1이면 5x10
                 I/D : 0이면 커서 왼쪽으로, 1이면 오른쪽으로 증가
                */
                INIT : begin 
                    // BL, EN, RW, RS

                    //0 3 3 3 2 2 8 0 c 0 1 0 6
                    
                    // CMD FUNCTION SET  - EN 0으로
                    rs = 1'b0; //for cmd

                    case (init_procedure)

                        INIT_PROCEDURE_1 : begin
                            if (cnt_us < 500) begin // 300us 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_4bit = 1'b1; // 하위 4bit만 전송
                                send_e = 1'b0;
                                send_buffer = 8'h03;    // 3 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1; // 대기 시간이 끝나면 데이터 전송,
                                next_init_procedure = INIT_PROCEDURE_2; // 다음 상태로
                            end                            
                        end

                        INIT_PROCEDURE_2 : begin
                            if (cnt_us < 8000) begin //5ms 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_e = 1'b0;
                                send_buffer = 8'h03; // 3 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;   // 5ms가 지나면 데이터 전송
                                next_init_procedure = INIT_PROCEDURE_3;
                            end                            
                        end

                        INIT_PROCEDURE_3 : begin
                            if (cnt_us < 8000) begin //5ms 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_e = 1'b0;
                                send_buffer = 8'h03; // 3 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;
                                next_init_procedure = INIT_PROCEDURE_4;
                            end                            
                        end

                        INIT_PROCEDURE_4 : begin
                            if (cnt_us < 800) begin //300us 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_e = 1'b0;
                                send_buffer = 8'h02; // 2 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;
                                next_init_procedure = INIT_PROCEDURE_5;
                            end                            
                        end

						//function set
                        INIT_PROCEDURE_5 : begin
                            if (cnt_us < 800) begin //300us 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_4bit = 1'b0;
                                send_e = 1'b0;
                                send_buffer = FUNCTION_SET; // 28 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;
                                next_init_procedure = INIT_PROCEDURE_6;
                            end                            
                        end

						//display off
                        INIT_PROCEDURE_6 : begin
                            if (cnt_us < 800) begin //300us 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_e = 1'b0;
                                send_buffer = DISPLAY_OFF; // 08 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;
                                next_init_procedure = INIT_PROCEDURE_7;
                            end                            
                        end

						//display clear
                        INIT_PROCEDURE_7 : begin
                            if (cnt_us < 800) begin //300us 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_e = 1'b0;
                                send_buffer = DISPLAY_CLR; // 01 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;
                                next_init_procedure = INIT_PROCEDURE_8;
                            end                            
                        end

						//entry mode set
                        INIT_PROCEDURE_8 : begin
                            if (cnt_us < 800) begin //300us 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_e = 1'b0;
                                send_buffer = ENTRYMODE_SET; // 06 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;
                                next_init_procedure = INIT_PROCEDURE_9;
                            end  
                        end

						//display on
                        INIT_PROCEDURE_9 : begin
                            if (cnt_us < 800) begin //300us 대기
                                cnt_us_e = 1'b1; // 타이머 시작
                                send_e = 1'b0;
                                send_buffer = DISPLAY_ON; // 0c 전송 준비
                            end
                            else begin
                                cnt_us_e = 1'b0; // 타이머 초기화
                                send_e = 1'b1;
                                next_init_procedure = INIT_COMPLETE;
                            end  
                        end

                        INIT_COMPLETE : begin
                            next_state = IDLE;
                            send_e = 1'b0;     
                            cnt_us_e = 1'b0;               
                        end

                    endcase
                end

                SEND : begin
					if (busy_flag == 0) begin
						send_buffer = data;    // 데이터 입력
						rs = rs_in;
						send_e = 1'b1;
						next_state = IDLE;
					end
					else begin
						next_state = SEND;
					end
                end

            endcase
 		end
	end

    i2c_lcd_4bit_mode_tx i2c_tx(.clk(clk),
                                .reset_p(reset_p),
                                .data_in(send_buffer),
                                .addr(addr),
                                .send(send_e),
                                .rs(rs),
                                .send_4bit(send_4bit),
                                .busy_flag(busy_flag),
                                .sda(sda),
                                .scl(scl) );
endmodule


module i2c_tx_xy (
    input clk, reset_p,
	input line, // 0: 1st line, 1: 2nd line
	input [6:0] pos, // 0~40
	input send, // 1: send
	input [7:0] data_in,
    output scl, sda);
                                // D=0 : display off, C=0 : cursor off, B=0 : blink off
                                // 0000_1 + D C B
    localparam SET_CURSOR_BLINK   = 8'b0000_1111;  // disply on, cursor on, blink on

                                //     0001 + S/C R/L X X
                                //     S/C: 1->display shift, 0->cursor shift
                                //     R/L: 1->right, 0->left

                                // 01 + ddram address -> cursor position
    localparam SET_DDRAM_ADDR_LINE1     = 8'b10_00_0000; // line 1 first address
    localparam SET_DDRAM_ADDR_LINE2     = 8'b11_00_0000; // line 2 first address

	localparam LINE1_FIRST_ADDR = 8'b0000_0000;
	localparam LINE2_FIRST_ADDR = 8'b0100_0000;

    localparam ADDR      = 7'h27;
    localparam RS_DATA = 1'b1;
    localparam RS_CMD  = 1'b0;

	localparam S_IDLE      = 6'b00_0001;
	localparam S_SEND_XY   = 6'b00_0010;
	localparam S_SEND_DATA = 6'b00_0100;

			// |  1  2  3  4   5  6  7  8   9 10 11 12  13 14 15 16  | 17 18 19 20  21 22 23 24  25 26 27 28  29 30 31 32  33 34 35 36  37 38 39 40
            // ------------------------------------------------------------------------------------------------------------------------------------
            // | 00 01 02 03  04 05 06 07  08 09 0A 0B  0C 0D 0E 0F  | 10 11 12 13  14 15 16 17  18 19 1A 1B  1C 1D 1E 1F  20 21 22 23  24 25 26 27
            // | 40 41 42 43  44 45 46 47  48 49 4A 4B  4C 4D 4E 4F  | 50 51 52 53  54 55 56 57  58 59 5A 5B  5C 5D 5E 5F  60 61 62 63  64 65 66 67

	// FSM
	reg [5:0]state, next_state;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= S_IDLE;
		end
		else begin
			state <= next_state;
		end
	end

	wire send_e;
	edge_detector_n edge_send(clk, reset_p, send, send_e);

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

    reg [7:0] data;
    reg send_data;
    reg rs;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            data = 8'b0;
            send_data = 1'b0;
            rs = RS_DATA; // 0: command, 1: data
			next_state = S_IDLE;
			cnt_us_e = 1'b0;
        end
        else begin
			case (state) 
				S_IDLE : begin
					send_data = 1'b0;
					if (send_e) begin
						next_state = S_SEND_XY;
					end
				end

				S_SEND_XY : begin
						// X Y 좌표 설정
						// line=0 : 1번째 줄
						// line=1 : 2번째 줄
					
					if (busy_flag == 0) begin
						if (cnt_us < 500) begin
							cnt_us_e = 1'b1; // 타이머 시작
							rs = RS_CMD;
							data = line ?  (SET_DDRAM_ADDR_LINE2+pos) : (SET_DDRAM_ADDR_LINE1+pos) ;
							send_data = 1'b1; // 좌표 이동 명령 전송
						end
						else begin
							next_state = S_SEND_DATA;
							send_data = 1'b0;
							cnt_us_e = 1'b0; // 타이머 초기화
						end
					end
					else begin // busy flag가 1이면 대기
						next_state = S_SEND_XY;
					end
				end

				S_SEND_DATA : begin
					if (busy_flag == 0) begin
						if (cnt_us < 500) begin
							cnt_us_e = 1'b1; // 타이머 시작
							rs = RS_DATA;
							data = data_in ;
							send_data = 1'b1;
						end
						else begin
							next_state = S_IDLE;
							send_data = 1'b0;
							cnt_us_e = 1'b0; // 타이머 초기화
						end
					end
					else begin // busy flag가 1이면 대기
						next_state = S_SEND_DATA;
					end
				end
			endcase
        end
    end
    
    i2c_tx_data i2c_tx_module(.clk(clk),
                              .reset_p(reset_p),
                              .addr(ADDR),
                              .rs_in(rs),
                              .data(data),
                              .send_data(send_data),
							  .busy_flag(busy_flag),
                              .scl(scl),
                              .sda(sda) );
endmodule

module i2c_tx_goto_xy (
    input clk, reset_p,
	input line, // 0: 1st line, 1: 2nd line
	input [6:0] pos, // 0~40
	input cmd_in_signal, // 1: send
	output reg [7:0] data,
	output reg send_data  );
                                // D=0 : display off, C=0 : cursor off, B=0 : blink off
                                // 0000_1 + D C B
    localparam SET_CURSOR_BLINK   = 8'b0000_1111;  // disply on, cursor on, blink on

                                //     0001 + S/C R/L X X
                                //     S/C: 1->display shift, 0->cursor shift
                                //     R/L: 1->right, 0->left
    localparam SHIFT_DIPLAY_RIGHT = 8'b0001_1100;
    localparam SHIFT_DIPLAY_LEFT  = 8'b0001_1000;
    localparam SHIFT_CURSOR_RIGHT = 8'b0001_0100;
    localparam SHIFT_CURSOR_LEFT  = 8'b0001_0000;
                                // 01 + ddram address -> cursor position
    localparam SET_DDRAM_ADDR_LINE1     = 8'b10_00_0000; // line 1 first address
    localparam SET_DDRAM_ADDR_LINE2     = 8'b11_00_0000; // line 2 first address

	localparam LINE1_FIRST_ADDR = 8'b0000_0000;
	localparam LINE2_FIRST_ADDR = 8'b0100_0000;

    localparam ADDR      = 7'h27;
    localparam RS_DATA = 1'b1;
    localparam RS_CMD  = 1'b0;

	localparam S_IDLE      = 6'b00_0001;
	localparam S_SEND_XY   = 6'b00_0010;
	localparam S_SEND_DATA = 6'b00_0100;

			// |  1  2  3  4   5  6  7  8   9 10 11 12  13 14 15 16  | 17 18 19 20  21 22 23 24  25 26 27 28  29 30 31 32  33 34 35 36  37 38 39 40
            // ------------------------------------------------------------------------------------------------------------------------------------
            // | 00 01 02 03  04 05 06 07  08 09 0A 0B  0C 0D 0E 0F  | 10 11 12 13  14 15 16 17  18 19 1A 1B  1C 1D 1E 1F  20 21 22 23  24 25 26 27
            // | 40 41 42 43  44 45 46 47  48 49 4A 4B  4C 4D 4E 4F  | 50 51 52 53  54 55 56 57  58 59 5A 5B  5C 5D 5E 5F  60 61 62 63  64 65 66 67

	// FSM
	reg [5:0]state, next_state;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= S_IDLE;
		end
		else begin
			state <= next_state;
		end
	end

	wire cmd_in_signal_p;
	edge_detector_n edge_send(clk, reset_p, cmd_in_signal, cmd_in_signal_p);

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

    reg rs;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            data = 8'b0;
            send_data = 1'b0;
            rs = RS_DATA; // 0: command, 1: data
			next_state = S_IDLE;
			cnt_us_e = 1'b0;
        end
        else begin
			case (state) 
				S_IDLE : begin
					send_data = 1'b0;
					if (cmd_in_signal_p) begin
						next_state = S_SEND_XY;
					end
				end

				S_SEND_XY : begin
					// X Y 좌표 설정
					// line=0 : 1번째 줄
					// line=1 : 2번째 줄
				
					if (cnt_us < 1500) begin
						cnt_us_e = 1'b1; // 타이머 시작
						rs = RS_CMD;
						data = line ?  (SET_DDRAM_ADDR_LINE2+pos) : (SET_DDRAM_ADDR_LINE1+pos) ;
						send_data = 1'b1; // 좌표 이동 명령 전송
					end
					else begin
						next_state = S_IDLE;
						send_data = 1'b0;
						cnt_us_e = 1'b0; // 타이머 초기화
					end
				end

			endcase
        end
    end
endmodule

module i2c_lcd_tx_string (
	input clk, reset_p,
	input [(16*8)-1:0] string, // 16 x 8bit(ascii)
	input [4:0] char_num,        // 입력 받을 문자열의 길이
	input data_in_signal,        // 문자 전송 신호
	output reg send,				 // 문자 전송 신호
	output reg busy_flag,		// busy flag
	output reg [7:0] char );         // 출력 문자 1개

	localparam S_IDLE         = 3'b001;
	localparam S_PARSING      = 3'b010;
	localparam S_SEND_CHAR	  = 3'b100;

	wire data_in_signal_p;
	edge_detector_n edge_send(clk, reset_p, data_in_signal, data_in_signal_p);

	reg [2:0] state, next_state;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= S_IDLE;
		end
		else begin
			state <= next_state;
		end
	end

	
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

	// 문자열 파싱 배열
	reg [7:0] char_parse[16-1:0];
	reg [5:0] i;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			i <= 0;
			cnt_us_e <= 0;
			send <= 0;
			char <= 8'b0;
			busy_flag <= 0;
			next_state <= S_IDLE;
			char_parse[0]  <= 8'b0;           
			char_parse[1]  <= 8'b0;           
			char_parse[2]  <= 8'b0;           
			char_parse[3]  <= 8'b0;           
			char_parse[4]  <= 8'b0;           
			char_parse[5]  <= 8'b0;           
			char_parse[6]  <= 8'b0;           
			char_parse[7]  <= 8'b0;           
			char_parse[8]  <= 8'b0;           
			char_parse[9]  <= 8'b0;           
			char_parse[10] <= 8'b0;           
			char_parse[11] <= 8'b0;           
			char_parse[12] <= 8'b0;           
			char_parse[13] <= 8'b0;           
			char_parse[14] <= 8'b0;           
			char_parse[15] <= 8'b0;           
		end
		else begin
			case(state) 
				S_IDLE : begin
					if (data_in_signal_p) begin
						next_state <= S_PARSING;
						busy_flag <= 1;
					end
					else begin
						next_state = S_IDLE;
						char <= 8'b0;
						char_parse[0]  <= 8'b0;
						char_parse[1]  <= 8'b0;
						char_parse[2]  <= 8'b0;
						char_parse[3]  <= 8'b0;
						char_parse[4]  <= 8'b0;
						char_parse[5]  <= 8'b0;
						char_parse[6]  <= 8'b0;
						char_parse[7]  <= 8'b0;
						char_parse[8]  <= 8'b0;
						char_parse[9]  <= 8'b0;
						char_parse[10] <= 8'b0;
						char_parse[11] <= 8'b0;
						char_parse[12] <= 8'b0;
						char_parse[13] <= 8'b0;
						char_parse[14] <= 8'b0;
						char_parse[15] <= 8'b0;
					end
				end

				S_PARSING : begin
					char_parse[ 0]  <= string[  7:  0];
					char_parse[ 1]  <= string[ 15:  8];
					char_parse[ 2]  <= string[ 23: 16];
					char_parse[ 3]  <= string[ 31: 24];
					char_parse[ 4]  <= string[ 39: 32];
					char_parse[ 5]  <= string[ 47: 40];
					char_parse[ 6]  <= string[ 55: 48];
					char_parse[ 7]  <= string[ 63: 56];
					char_parse[ 8]  <= string[ 71: 64];
					char_parse[ 9]  <= string[ 79: 72];
					char_parse[10]  <= string[ 87: 80];
					char_parse[11]  <= string[ 95: 88];
					char_parse[12]  <= string[103: 96];
					char_parse[13]  <= string[111:104];
					char_parse[14]  <= string[119:112];
					char_parse[15]  <= string[127:120];
					next_state <= S_SEND_CHAR;
				end

				S_SEND_CHAR : begin // char_num이 8이면 7까지 돌리면 됨
					if (i < char_num) begin // 문자열 길이만큼 반복
						if (cnt_us < 2000) begin // 500us 동안
							cnt_us_e <= 1; // 카운터 시작
							char <= char_parse[char_num-i-1]; //n-1부터 시작
							send <= 1; // 문자 전송
						end
						else begin
							cnt_us_e <= 0; // 카운터 초기화
							send <= 0;
							i <= i + 1; // 다음 문자로 이동
						end
					end
					else begin //모든 문자 전송 후 대기 상태로
						next_state <= S_IDLE;
						busy_flag <= 0;
						i <= 0;						
					end
				end
			endcase
		end
	end



endmodule


module i2c_txt_lcd_top (
    input clk, reset_p,
    input rs, // 0: command, 1: data
    input line, //라인 넘버 0, 1 -> 1번줄 2번줄
    input [6:0] pos, // x좌표
    input [(16*8)-1:0] string, // 16 x 8bit(ascii)
    input [4:0] char_num,        // 입력 받을 문자열의 길이
    input send, //전송 신호
	output reg init_flag,
    output scl, sda);

    localparam ADDR = 7'h27;

    localparam IDLE         = 6'b00_0001;
    localparam WAIT         = 6'b00_0010;
    localparam INIT         = 6'b00_0100;
    localparam SEND_DATA    = 6'b00_1000;
    localparam SEND_CMD_XY  = 6'b01_0000;

    localparam RS_DATA = 1'b1;
    localparam RS_CMD  = 1'b0;
    localparam EN_0    = 1'b0;
    localparam EN_1    = 1'b1;

                                        // 01 + ddram address -> cursor position
    localparam SET_DDRAM_ADDR_LINE1     = 8'b10_00_0000; // line 1 first address
    localparam SET_DDRAM_ADDR_LINE2     = 8'b11_00_0000; // line 2 first address
    
    localparam SHIFT_DIPLAY_RIGHT = 8'b0001_1100;
    localparam SHIFT_DIPLAY_LEFT  = 8'b0001_1000;
    localparam SHIFT_CURSOR_RIGHT = 8'b0001_0100;
    localparam SHIFT_CURSOR_LEFT  = 8'b0001_0000;


    reg [7:0] send_buffer;

    edge_detector_n ed_send(.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_p) );

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

	// FSM
	reg [5:0]state, next_state;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= IDLE;
		end
		else begin
			state <= next_state;
		end
	end

    reg send_e;
    reg [7:0] data_out;
    reg [7:0] cmd_out;
    reg [7:0] char_parse[15:0];
    reg [5:0] i;
    always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
            i <= 0;
            data_out <= 8'b0;
            cmd_out <= 8'b0;
			next_state <= IDLE;
            send_buffer <= 8'b0;
            send_e <= 1'b0;
            init_flag <= 1'b0;
			char_parse[0]  <= 8'b0;           
			char_parse[1]  <= 8'b0;           
			char_parse[2]  <= 8'b0;           
			char_parse[3]  <= 8'b0;           
			char_parse[4]  <= 8'b0;           
			char_parse[5]  <= 8'b0;           
			char_parse[6]  <= 8'b0;           
			char_parse[7]  <= 8'b0;           
			char_parse[8]  <= 8'b0;           
			char_parse[9]  <= 8'b0;           
			char_parse[10] <= 8'b0;           
			char_parse[11] <= 8'b0;           
			char_parse[12] <= 8'b0;           
			char_parse[13] <= 8'b0;           
			char_parse[14] <= 8'b0;           
			char_parse[15] <= 8'b0;   
		end
		else begin
			case (state)
                IDLE : begin
                    if (init_flag == 1) begin //rs = 1이면 데이터 쓰기 0이면 좌표이동모드
                        if(send_p) begin
                            if (rs) begin
                                next_state <= SEND_DATA;
                                char_parse[ 0]  <= string[  7:  0];
                                char_parse[ 1]  <= string[ 15:  8];
                                char_parse[ 2]  <= string[ 23: 16];
                                char_parse[ 3]  <= string[ 31: 24];
                                char_parse[ 4]  <= string[ 39: 32];
                                char_parse[ 5]  <= string[ 47: 40];
                                char_parse[ 6]  <= string[ 55: 48];
                                char_parse[ 7]  <= string[ 63: 56];
                                char_parse[ 8]  <= string[ 71: 64];
                                char_parse[ 9]  <= string[ 79: 72];
                                char_parse[10]  <= string[ 87: 80];
                                char_parse[11]  <= string[ 95: 88];
                                char_parse[12]  <= string[103: 96];
                                char_parse[13]  <= string[111:104];
                                char_parse[14]  <= string[119:112];
                                char_parse[15]  <= string[127:120];
                            end
                            else begin
                                next_state <= SEND_CMD_XY;
                            end
                        end
                        else next_state <= IDLE;
                    end
                    else next_state <= WAIT;
                end
                
                WAIT : begin // 40ms 대기하고
                    if (cnt_us <= 20'd40_000) begin
                            cnt_us_e <= 1'b1;
                        end
                    else begin // 40ms가 지나면 INIT 진행
                        next_state = INIT;
                        cnt_us_e <= 1'b0; //타이머를 초기화
                    end
                end
                /*
                 N : 0이면 1줄, 1이면 2줄
                 F : 0이면 5x8, 1이면 5x10
                 I/D : 0이면 커서 왼쪽으로, 1이면 오른쪽으로 증가
                */
                INIT : begin 
                    // BL, EN, RW, RS
                    cnt_us_e = 1'b1;

                    // 3 3 3 2 2 8 0 c 0 1 0 6
                    // CMD FUNCTION SET  - EN 0으로
                    if      (cnt_us <= 20'd100) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd200) send_e      = 1'b1;
                    else if (cnt_us <= 20'd300) send_e      = 1'b0;

                    // CMD FUNCTION SET - 0011 전송
                    else if (cnt_us <= 20'd4500) send_buffer = {4'b0011, 4'b0100};
                    else if (cnt_us <= 20'd4600) send_e      = 1'b1;
                    else if (cnt_us <= 20'd4700) send_e      = 1'b0;
                    else if (cnt_us <= 20'd4800) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd4900) send_e      = 1'b1;
                    else if (cnt_us <= 20'd5000) send_e      = 1'b0;

                    // CMD FUNCTION SET - 4ms 이후 0011 전송
                    else if (cnt_us <= 20'd9000) send_buffer = {4'b0011, 4'b0100};
                    else if (cnt_us <= 20'd9100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd9200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd9300) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd9400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd9500) send_e      = 1'b0;

                    // CMD FUNCTION SET - 4ms 이후 0011 전송
                    else if (cnt_us <= 20'd14000) send_buffer = {4'b0011, 4'b0100};
                    else if (cnt_us <= 20'd14100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd14200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd14300) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd14400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd14500) send_e      = 1'b0;

                    // 4ms 이후 0010 전송
                    else if (cnt_us <= 20'd18000) send_buffer = {4'b0010, 4'b0100};
                    else if (cnt_us <= 20'd18100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd18200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd18300) send_buffer = {4'b0010, 4'b0000};
                    else if (cnt_us <= 20'd18400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd18500) send_e      = 1'b0;

                    // 100us 이후 0010_1000
                    else if (cnt_us <= 20'd19000) send_buffer = {4'b0010, 4'b0100};
                    else if (cnt_us <= 20'd19100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd19200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd19300) send_buffer = {4'b0010, 4'b0000};
                    else if (cnt_us <= 20'd19400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd19500) send_e      = 1'b0;
                    else if (cnt_us <= 20'd19600) send_buffer = {4'b1000, 4'b0100};
                    else if (cnt_us <= 20'd19700) send_e      = 1'b1;
                    else if (cnt_us <= 20'd19800) send_e      = 1'b0;
                    else if (cnt_us <= 20'd19900) send_buffer = {4'b1000, 4'b0000};
                    else if (cnt_us <= 20'd20000) send_e      = 1'b1;
                    else if (cnt_us <= 20'd20100) send_e      = 1'b0;

                    // 100us 이후 0000_1110
                    else if (cnt_us <= 20'd20200) send_buffer = {4'b0000, 4'b0100};
                    else if (cnt_us <= 20'd20300) send_e      = 1'b1;
                    else if (cnt_us <= 20'd20400) send_e      = 1'b0;
                    else if (cnt_us <= 20'd20500) send_buffer = {4'b0000, 4'b0000};
                    else if (cnt_us <= 20'd20600) send_e      = 1'b1;
                    else if (cnt_us <= 20'd20700) send_e      = 1'b0;
                    else if (cnt_us <= 20'd20800) send_buffer = {4'b1100, 4'b0100};
                    else if (cnt_us <= 20'd20900) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21000) send_e      = 1'b0;
                    else if (cnt_us <= 20'd21100) send_buffer = {4'b1100, 4'b0000};
                    else if (cnt_us <= 20'd21200) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21300) send_e      = 1'b0;

                    // 100us 이후 0000_0001
                    else if (cnt_us <= 20'd21400) send_buffer = {4'b0000, 4'b0100};
                    else if (cnt_us <= 20'd21500) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21600) send_e      = 1'b0;
                    else if (cnt_us <= 20'd21700) send_buffer = {4'b0000, 4'b0000};
                    else if (cnt_us <= 20'd21800) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21900) send_e      = 1'b0;
                    else if (cnt_us <= 20'd22000) send_buffer = {4'b0001, 4'b0100};
                    else if (cnt_us <= 20'd22100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd22200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd22300) send_buffer = {4'b0001, 4'b0000};
                    else if (cnt_us <= 20'd22400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd22500) send_e      = 1'b0;

                    // 2ms 이후 0000_0110
                    else if (cnt_us <= 20'd22600) send_buffer = {4'b0000, 4'b0100};
                    else if (cnt_us <= 20'd22700) send_e      = 1'b1;
                    else if (cnt_us <= 20'd22800) send_e      = 1'b0;
                    else if (cnt_us <= 20'd22900) send_buffer = {4'b0000, 4'b0000};
                    else if (cnt_us <= 20'd23000) send_e      = 1'b1;
                    else if (cnt_us <= 20'd23100) send_e      = 1'b0;
                    else if (cnt_us <= 20'd23200) send_buffer = {4'b0110, 4'b0100};
                    else if (cnt_us <= 20'd23300) send_e      = 1'b1;
                    else if (cnt_us <= 20'd23400) send_e      = 1'b0;
                    else if (cnt_us <= 20'd23500) send_buffer = {4'b0110, 4'b1000};
                    else if (cnt_us <= 20'd23600) send_e      = 1'b1;
                    else if (cnt_us <= 20'd23700) send_e      = 1'b0;

                    // 종료
                    else if (cnt_us <= 20'd23800) begin
                        init_flag <= 1'b1;
                        next_state <= IDLE;
                        cnt_us_e = 1'b0;
                    end
                end

                SEND_CMD_XY : begin

                    cnt_us_e = 1'b1;

                    cmd_out = line ? (SET_DDRAM_ADDR_LINE2+pos) : (SET_DDRAM_ADDR_LINE1+pos) ;

                    if      (cnt_us <= 20'd100) send_buffer  = {cmd_out[7:4], 1'b1, EN_1, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd200) send_e       = 1'b1;
                    else if (cnt_us <= 20'd300) send_e       = 1'b0;
 
                    else if (cnt_us <= 20'd400) send_buffer  = {cmd_out[7:4], 1'b1, EN_0, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd500) send_e       = 1'b1;
                    else if (cnt_us <= 20'd600) send_e       = 1'b0;

                    else if (cnt_us <= 20'd700) send_buffer = {cmd_out[3:0], 1'b1, EN_1, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd800) send_e      = 1'b1;
                    else if (cnt_us <= 20'd900) send_e      = 1'b0;

                    else if (cnt_us <= 20'd1000) send_buffer = {cmd_out[3:0], 1'b1, EN_0, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd1100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd1200) send_e      = 1'b0;

                    // 종료
                    else if (cnt_us <= 20'd1300) begin
                        next_state <= IDLE;
                        cnt_us_e = 1'b0;
                    end
                end

                SEND_DATA : begin
                    
                    cnt_us_e = 1'b1;                    
                    data_out = char_parse[char_num-1-i];
                    if      (cnt_us <= 20'd100) send_buffer  = {data_out[7:4], 1'b1, EN_1, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd200) send_e       = 1'b1;
                    else if (cnt_us <= 20'd300) send_e       = 1'b0;
 
                    else if (cnt_us <= 20'd400) send_buffer  = {data_out[7:4], 1'b1, EN_0, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd500) send_e       = 1'b1;
                    else if (cnt_us <= 20'd600) send_e       = 1'b0;

                    else if (cnt_us <= 20'd700) send_buffer = {data_out[3:0], 1'b1, EN_1, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd800) send_e      = 1'b1;
                    else if (cnt_us <= 20'd900) send_e      = 1'b0;

                    else if (cnt_us <= 20'd1000) send_buffer = {data_out[3:0], 1'b1, EN_0, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd1100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd1200) send_e      = 1'b0;

                    // 종료
                    else if (cnt_us <= 20'd1300) begin
                        i = i + 1;
                        cnt_us_e = 1'b0;
                        if (i == char_num) begin
                            next_state <= IDLE;
                            i = 0;
                        end
                        else begin
                            next_state <= SEND_DATA;
                        end
                    end
                end

            endcase
 		end
	end

    i2c_master i2c( .clk(clk),
                    .reset_p(reset_p),
                    .rw(1'b0),
                    .addr(ADDR),
                    .data_in(send_buffer),
                    .valid(send_e),
                    .sda(sda),
                    .scl(scl) );
endmodule


module fan_info( 
    input clk, reset_p,
    input [3:0] btn,
    output scl, sda );
    
    localparam INIT_DEFAULT = 10'b00_0000_0001;
    localparam GOTO_TEMP    = 10'b00_0000_0010;
    localparam TEMPERATURE  = 10'b00_0000_0100;
    localparam GOTO_TIME    = 10'b00_0000_1000;
    localparam REMAING_TIME = 10'b00_0001_0000;
    localparam GOTO_BAT     = 10'b00_1000_0000;
    localparam REMAING_BAT  = 10'b01_0000_0000;

    wire init_flag;
    
    
    wire clk_usec, clk_msec, clk_sec;
	clock_usec # (125) usec (clk, reset_p, clk_usec);
    clock_div_1000     msec (clk, reset_p, clk_usec, clk_msec);
    clock_div_1000      sec (clk, reset_p, clk_msec, clk_sec);

    wire [3:0] btn_p;
    button_cntr btn_0(clk, reset_p, btn[0], btn_p[0]);

    

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

	// FSM
	reg [9:0]state, next_state;
    assign led_bar = state[7:0];
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= INIT_DEFAULT;
		end
		else begin
			state <= next_state;
		end
	end

    reg [7:0] temp_10, temp_1;
    reg [7:0] time_m_10, time_m_1, time_s_10, time_s_1;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            temp_10     <= 2;
            temp_1      <= 4;
            time_m_10   <= 0;
            time_m_1    <= 0;
            time_s_10   <= 0;
            time_s_1    <= 0;
        end
        else begin
            if (clk_sec) begin
                time_s_1 = time_s_1 + 1;
                if (time_s_1 == 10) begin
                    time_s_1 = 0;
                    time_s_10 = time_s_10 + 1;
                end
                if (time_s_10 == 6) begin
                    time_s_10 = 0;
                    time_m_1 = time_m_1 + 1;
                end
                if (time_m_1 == 10) begin
                    time_m_1 = 0;
                    time_m_10 = time_m_10 + 1;
                end
                if (time_m_10 == 6) begin
                    time_m_10 = 0;
                end
            end 

            if (btn_p[0]) begin
                temp_1 = temp_1 + 1;
                if (temp_1 == 10) begin
                    temp_1 = 0;
                    temp_10 = temp_10 + 1;
                end
                if (temp_10 == 10) temp_10 = 0;
            end
           
        end
    end
    reg rs;
    reg line;
    reg [6:0] pos;
    reg [(16*8)-1:0] string;
    reg [4:0] char_num;
    reg send;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            rs = 0;
            line = 0;
            pos = 0;
            string = 128'b0;
            char_num = 0;
            send = 0;
            cnt_us_e = 0;
            next_state = INIT_DEFAULT;
        end
        else if (init_flag) begin
            case (state)
                INIT_DEFAULT : begin
                    if (cnt_us < 1_000) begin //3ms
                        string ={"TEMP  :       " , 8'b1101_1111,"C"}; // "TEMP : 20'C"
                        cnt_us_e = 1;
                        char_num = 16;
                        rs = 1;
                        send = 1;
                    end
                    else if (cnt_us < 20_000) begin
                        send = 0;
                    end
                    else if (cnt_us < 25_000) begin
                        line = 1;
                        pos = 0;
                        rs = 0;
                        send = 1;
                    end
                    else if (cnt_us < 26_000) begin
                        send = 0;
                    end
                    else if (cnt_us < 30_000) begin
                        string ="TIMER :         ";
                        char_num = 16;
                        rs = 1;
                        send = 1;
                    end
                    else if (cnt_us < 50_000) begin
                        send = 0;
                    end
                    else begin
                        cnt_us_e = 0;
                        next_state = GOTO_TEMP;
                    end
                end

                GOTO_TEMP : begin // temp로 커서 이동
                    if (cnt_us < 100_000) begin
                        cnt_us_e = 1;
                        line = 0;
                        pos = 12;
                        rs = 0;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = TEMPERATURE;
                    end
                end

                TEMPERATURE : begin
                    if (cnt_us < 100_000) begin //3ms
                        cnt_us_e = 1;
                        string = {temp_10+8'h30, temp_1+8'h30}; // "TEMP : 20'C"
                        char_num = 2;
                        rs = 1;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = GOTO_TIME;                        
                    end
                end

                GOTO_TIME : begin
                    if (cnt_us < 100_000) begin
                        cnt_us_e = 1;
                        line = 1;
                        pos = 10;
                        rs = 0;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = REMAING_TIME;
                    end
                end

                REMAING_TIME : begin
                    if (cnt_us < 100_000) begin //3ms
                        cnt_us_e = 1;
                        string = {time_m_10+8'h30, time_m_1+8'h30,"m", time_s_10+8'h30, time_s_1+8'h30,"s"};
                        char_num = 6;
                        rs = 1;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = GOTO_TEMP;                        
                    end
                end
            endcase
        end
    end


    i2c_txt_lcd_top str(.clk        (clk),
                        .reset_p    (reset_p),
                        .rs         (rs),
                        .line       (line),
                        .pos        (pos),
                        .string     (string),
                        .char_num   (char_num),
                        .send       (send),
                        .init_flag  (init_flag),
                        .scl        (scl),
                        .sda        (sda) );
endmodule