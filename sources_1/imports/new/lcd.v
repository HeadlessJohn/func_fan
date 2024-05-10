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
	output [7:0] led_bar,
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

	assign led_bar = {1'b0, state};

endmodule


module i2c_lcd_tx_byte (
	input clk, reset_p,
	input [7:0] send_buffer,
	input send, rs,
	output [7:0] led_bar,
	output reg [7:0] data_out,
	output reg valid,
	output reg busy_flag   );

	localparam BL_ON = 1'b1; // 백라이트 켜기
	localparam BL_OFF = 1'b0; // 백라이트 끄기
	localparam EN_0 = 1'b0; // enable 1
	localparam EN_1 = 1'b1; // enable 0
	localparam WRITE = 1'b0; // write
	localparam READ = 1'b1; // read
	localparam RS_CMD = 1'b0; // command
	localparam RS_DATA = 1'b1; // data

	localparam S_IDLE				  		 = 6'b00_0001;
	localparam S_SEND_HIGH_NIBBLE_DISABLE  	 = 6'b00_0010;
	localparam S_SEND_HIGH_NIBBLE_ENABLE 	 = 6'b00_0100;
	localparam S_SEND_LOW_NIBBLE_DISABLE  	 = 6'b00_1000;
	localparam S_SEND_LOW_NIBBLE_ENABLE 	 = 6'b01_0000;
	localparam S_SEND_DISABLE 				 = 6'b10_0000;

	// send 버튼 edge detector
	wire send_p;
	edge_detector_n edge_send(clk, reset_p, send, send_p);

	wire clk_usec;
	clock_usec # (125) clk_us(clk, reset_p, clk_usec);

	// ms 카운터
	reg [12:0] cnt_us;
	reg cnt_us_e;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_us <= 12'b0;
		end
		else begin
			if (cnt_us_e) begin
				if (clk_usec) begin
					cnt_us <= cnt_us + 1;
				end
			end
			else begin
				cnt_us <= 12'b0;
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

	/*
	{data, bl, en, rw, rs}
	D7 |D6 |D5 |D4 |BL |EN |RW | RS
	[ 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 ]

	RW : 0 쓰기, 1 읽기
	RS : 0 명령어, 1 데이터

	4bit mode
	주소 보내고
	데이터(명령) 상위 4비트 보내고
	en 1->0
	데이터(명령) 하위 4비트 보내기
	en 1->0

	{addr + W} = 0x27 = 0100_1110
	en : 0x04

	*/

	always @(posedge clk, posedge reset_p) begin
		if(reset_p) begin
			data_out <= 8'b0;
			cnt_us_e <= 0;
			valid <= 0;
			next_state <= S_IDLE;
			busy_flag <= 0;
		end
		else begin
			case (state)
				// IDLE
				S_IDLE : begin
					if (send_p) begin // send_p 입력 들어오면
						valid <= 0;
						busy_flag <= 1;
						next_state <= S_SEND_HIGH_NIBBLE_DISABLE;
					end
				end

				// 상위 4비트 전송 준비
				S_SEND_HIGH_NIBBLE_DISABLE : begin
					if (cnt_us <= 200) begin //20us 동안 EN 1로 유지
						data_out <= {send_buffer[7:4], BL_ON, EN_1, WRITE, rs};
						valid <= 0; // 데이터 전송
						cnt_us_e <= 1; // 시간 측정 시작
					end
					else begin // 200us 이후 상위 4비트 전송 준비
						next_state <= S_SEND_HIGH_NIBBLE_ENABLE; // 다음 상태로
						cnt_us_e <= 0; // 타이머 초기화
						valid <= 1;
					end
				end

				// 상위 4비트 전송
				S_SEND_HIGH_NIBBLE_ENABLE : begin
					if (cnt_us <= 1600) begin //20us 동안 EN 1로 유지
						data_out <= {send_buffer[7:4], BL_ON, EN_0, WRITE, rs};
						valid <= 0; // 데이터 전송
						cnt_us_e <= 1; // 시간 측정 시작
					end
					else begin // 1600us 이후 상위 4비트 전송 준비
						next_state <= S_SEND_LOW_NIBBLE_DISABLE; // 다음 상태로
						cnt_us_e <= 0; // 타이머 초기화
						valid <= 1;
					end
				end

				// 하위 4비트 전송 준비
				S_SEND_LOW_NIBBLE_DISABLE : begin
					if (cnt_us <= 200) begin //20us 동안 EN 1로 유지
						data_out <= {send_buffer[3:0], BL_ON, EN_1, WRITE, rs};
						valid <= 0; // 데이터 전송
						cnt_us_e <= 1; // 시간 측정 시작
					end
					else begin // 200us 이후 상위 4비트 전송 준비
						next_state <= S_SEND_LOW_NIBBLE_ENABLE; // 다음 상태로
						cnt_us_e <= 0; // 타이머 초기화
						valid <= 1;
					end
				end

				// 하위 4비트 전송
				S_SEND_LOW_NIBBLE_ENABLE : begin
					if (cnt_us <= 1600) begin //20us 동안 EN 1로 유지
						data_out <= {send_buffer[3:0], BL_ON, EN_0, WRITE, rs};
						valid <= 0; // 데이터 전송
						cnt_us_e <= 1; // 시간 측정 시작
					end
					else begin // 1600us 이후 상위 4비트 전송 준비
						next_state <= S_IDLE; // 다음 상태로
						cnt_us_e <= 0; // 타이머 초기화
						valid <= 1;
						busy_flag <= 0;
					end
				end

				/*
				//전송 중지
				S_SEND_DISABLE : begin
					if (cnt_us <= 200) begin
						data_out = {data_out[7:4], BL_ON, EN_0, data_out[1:0]}; // EN 0으로 전송
						valid <= 1; // 데이터 전송 중지
						cnt_us_e <= 1; // 시간 측정 시작
					end
					else begin
						next_state <= S_IDLE; // 다음 상태로
						cnt_us_e <= 0; // 타이머 초기화
						valid <= 0;
						busy_flag <= 0;
					end

				end
				*/
			endcase
		end
	end
	assign led_bar = {busy_flag, send, state};

endmodule

module i2c_transmit_byte (
	input clk, reset_p,
	input [7:0] data_in, //입력 데이터
	input valid, //시작 신호
	output reg sda,
	output reg scl );

	localparam S_IDLE      		 = 6'b00_0001;
	localparam S_COMM_START		 = 6'b00_0010;
	localparam S_RD_ACK    		 = 6'b00_0100;
	localparam S_SEND_DATA 		 = 6'b00_1000;
	localparam S_SCL_STOP  		 = 6'b01_0000;
	localparam S_COMM_STOP 		 = 6'b10_0000;


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
	reg [2:0] cnt_stop;
	always @(posedge clk or posedge reset_p)begin
		if(reset_p) begin
			sda <= 1'b1;
			next_state <= S_IDLE;
			scl_toggle_e <= 1'b0;
			d_out_cnt <= 7;
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
					next_state <= S_SEND_DATA; // 다음 상태로
				end
				
				S_SEND_DATA : begin // 최상위비트부터 전송 시작
					if(scl_n) sda <= data_in[d_out_cnt];
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
						next_state <= S_SCL_STOP; 
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
