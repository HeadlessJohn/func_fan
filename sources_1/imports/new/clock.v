`timescale 1ns / 1ps


//1us clock generator
module clock_usec # (
	parameter freq = 125 //Mhz
	)(
	input clk, reset_p,
	output clock_usec );
	
	localparam half_freq = freq/2;
	
	reg [6:0] cnt_sysclk; //1clk = 8ns
	wire cp_usec; // 반주기동안 0, 반주기동안 1

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) cnt_sysclk =0;
		else if (cnt_sysclk >= freq-1) cnt_sysclk = 0;
		else cnt_sysclk = cnt_sysclk + 1;
	end

	//0.5us에 상승엣지 발생, 1us에 하강엣지 발생
	//cp_usec
	// ___________----------__________---------________
	// 0        0.5us      1us      1.5us     2us
	assign cp_usec = (cnt_sysclk < half_freq) ? 0 : 1;

	//1us 클록 엣지 검출 펄스 출력
	//clock_usec
	// _____________________-__________________-______
	// 0                 1us+(clk/2)        2us+(clk/2)
	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_usec),
		.n_edge(clock_usec)
	);
endmodule


//1ms clock generator
//2개 연결하면 1초 클록 생성
module clock_div_1000 (
	input clk, reset_p,
	input clk_source,
	output clock_div_1000 );

	reg [8:0] cnt;
	reg cp_div_1000;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt = 0;
			cp_div_1000 = 0;
		end
		else if (clk_source) begin
			if (cnt >= 499) begin 
				cnt = 0;
				cp_div_1000 = ~cp_div_1000;
			end
			else cnt = cnt + 1;
		end
	end

	//0.5ms에 상승엣지 발생, 1ms에 하강엣지 발생
	//cp_msec
	// ___________----------__________---------________
	// 0        0.5ms      1ms      1.5ms    2ms
	// assign cp_msec = (cnt < 500) ? 0 : 1;

	//1ms 클록 엣지 검출 펄스 출력
	//clock_msec
	// _____________________-__________________-______
	// 0                 1ms+(clk/2)        2ms+(clk/2)
	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_div_1000),
		.n_edge(clock_div_1000) );
endmodule

module clock_div_N #(
	parameter N = 1000
)(
	input clk, reset_p,
	input clk_source,
	output clock_div_N );

	reg [8:0] cnt;
	reg cp_div_N;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt = 0;
			cp_div_N = 0;
		end
		else if (clk_source) begin
			if (cnt >= (N/2) -1) begin 
				cnt = 0;
				cp_div_N = ~cp_div_N;
			end
			else cnt = cnt + 1;
		end
	end

	//0.5ms에 상승엣지 발생, 1ms에 하강엣지 발생
	//cp_msec
	// ___________----------__________---------________
	// 0        0.5ms      1ms      1.5ms    2ms
	// assign cp_msec = (cnt < 500) ? 0 : 1;

	//1ms 클록 엣지 검출 펄스 출력
	//clock_msec
	// _____________________-__________________-______
	// 0                 1ms+(clk/2)        2ms+(clk/2)
	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_div_N),
		.n_edge(clock_div_N) );
endmodule

//1us clock generator
module clock_usec_duty50 # (
	parameter freq = 125, //Mhz
	parameter half_freq = freq/2
	)(
	input clk, reset_p,
	output cp_usec,
	output clock_usec );
	
	reg [6:0] cnt_sysclk; //1clk = 8ns

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) cnt_sysclk =0;
		else if (cnt_sysclk >= freq-1) cnt_sysclk = 0;
		else cnt_sysclk = cnt_sysclk + 1;
	end

	//0.5us에 상승엣지 발생, 1us에 하강엣지 발생
	//cp_usec
	// ___________----------__________---------________
	// 0        0.5us      1us      1.5us     2us
	assign cp_usec = (cnt_sysclk < half_freq) ? 0 : 1;

	//1us 클록 엣지 검출 펄스 출력
	//clock_usec
	// _____________________-__________________-______
	// 0                 1us+(clk/2)        2us+(clk/2)
	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_usec),
		.n_edge(clock_usec)
	);
endmodule


//1ms clock generator
//2개 연결하면 1초 클록 생성
module clock_div_1000_duty50 (
	input clk, reset_p,
	input clk_source,
	output reg cp_div_1000 );

	reg [8:0] cnt;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt = 0;
			cp_div_1000 = 0;
		end
		else if (clk_source) begin
			if (cnt >= 499) begin 
				cnt = 0;
				cp_div_1000 = ~cp_div_1000;
			end
			else cnt = cnt + 1;
		end
	end

endmodule

module clock_div_10 (
	input clk, reset_p,
	input clk_source,
	output clock_div_10 );

	integer cnt; //32bit
	reg cp_div_10;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt = 0;
			cp_div_10 = 0;
		end
		else if (clk_source) begin
			if (cnt >= 4) begin 
				cnt = 0;
				cp_div_10 = ~cp_div_10;
			end
			else cnt = cnt + 1;
		end
	end

	//0.5ms에 상승엣지 발생, 1ms에 하강엣지 발생
	//cp_msec
	// ___________----------__________---------________
	// 0        0.5ms      1ms      1.5ms    2ms
	// assign cp_msec = (cnt < 500) ? 0 : 1;

	//1ms 클록 엣지 검출 펄스 출력
	//clock_msec
	// _____________________-__________________-______
	// 0                 1ms+(clk/2)        2ms+(clk/2)
	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_div_10),
		.n_edge(clock_div_10) );
endmodule

module clock_min (
	input clk, reset_p,
	input clk_sec,
	output clock_min);

	reg [5:0] cnt;
	wire cp_min;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) cnt = 0;
		else if (cnt > 59)  cnt = 0;		
		else if (clk_sec) cnt = cnt + 1;
	end

	assign cp_min = (cnt < 30) ? 0 : 1;

	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_min),
		.n_edge(clock_min) );
endmodule


module counter_dec_60(
	input clk, reset_p,
	input clk_time,
	output reg [3:0] digit_1, digit_10
	);

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit_1 = 0;
			digit_10 = 0;
		end
		else begin
			if (clk_time) begin
				if (digit_1 >= 9) begin 
					digit_1 = 0; //1의자리 10진 카운터

					if (digit_10 >= 5) digit_10 = 0; 
					else digit_10 = digit_10 + 1; //10의자리 1증가 59까지 카운트
				end
				else begin digit_1 = digit_1 + 1;
				end
			end
		end
	end
endmodule


// pause 추가된 1us clock generator
module clock_usec_pause # (
	parameter freq = 12, //Mhz
	parameter half_freq = freq/2
	)(
	input clk, reset_p,
	output clock_usec,
	input pause
	);
	
	reg [6:0] cnt_sysclk; //1clk = 8ns
	wire cp_usec; // 반주기동안 0, 반주기동안 1

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) cnt_sysclk =0;
		else if (cnt_sysclk >= freq-1) cnt_sysclk = 0;
		else cnt_sysclk = pause ? cnt_sysclk : cnt_sysclk + 1;
	end

	assign cp_usec = (cnt_sysclk < half_freq) ? 0 : 1;

	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_usec),
		.n_edge(clock_usec)
	);
endmodule

// pause, inc, dec 추가된 1min clock generator
module clock_min_pause (
	input clk, reset_p,
	input clk_sec,
	output clock_min,
	input pause,
	input inc, dec
	);

	reg [5:0] cnt;
	wire cp_min;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt = 0;
		end
		else begin
			if (cnt > 59)  cnt = 0;		
			else if (pause) begin 
				if (inc) cnt = cnt + 1;
				else if (dec) cnt = cnt - 1;
			end
			else if (pause==0) begin
				if(clk_sec) cnt = cnt + 1;
			end
		end
	end

	assign cp_min = (cnt < 30) ? 0 : 1;

	//cp_min의 하강엣지 검출
	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_min),
		.n_edge(clock_min) );
endmodule 

// pause, inc, dec 추가된 60진 카운터
module counter_dec_60_up_down(
	input clk, reset_p,
	input clk_time,
	output reg [3:0] digit_1, digit_10,
	input pause, inc, dec
	);

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit_1 = 0;
			digit_10 = 0;
		end
		else if (clk_time|pause) begin
			if (pause) begin
				if (dec) digit_1 = digit_1 - 1;
				else if (inc) digit_1 = digit_1 + 1;
			end
			else if (pause==0) begin
				digit_1 = digit_1 + 1;
			end

			if (digit_1 > 9) begin 
				digit_1 = 0; //1의자리 10진 카운터
				if (digit_10 >= 5) digit_10 = 0; 
				else digit_10 = digit_10 + 1; //10의자리 1증가 59까지 카운트
			end
		end
	end
endmodule

module clk_1sec (
	input clk, reset_p,
	input clk_source,
	output reg cp_div_1000
	);

	reg [8:0] cnt;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt = 0;
			cp_div_1000 = 0;
		end
		else if (clk_source) begin
			if (cnt >= 499) begin 
				cnt = 0;
				cp_div_1000 = ~cp_div_1000;
			end
			else cnt = cnt + 1;
		end
	end

endmodule


module loadable_counter_dec_60(
	input clk, reset_p,
	input clk_time,
	input load_enable,
	input [3:0] set_value_1, set_value_10,
	output reg [3:0] digit_1, digit_10,
	output reg ovf
	);

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit_1 = 0;
			digit_10 = 0;
		end
		else begin
			//load_enable 1이면 set_value를 입력
			if (load_enable) begin
				digit_1 = set_value_1;
				digit_10 = set_value_10;
			end
			else if (clk_time) begin
				if (digit_1 >= 9) begin 
					digit_1 = 0; //1의자리 10진 카운터

					if (digit_10 >= 5) begin 
						digit_10 = 0;
						ovf = 1; 
					end
					else digit_10 = digit_10 + 1; //10의자리 1증가 59까지 카운트
				end
				else begin digit_1 = digit_1 + 1;
				end
			end 
			else ovf = 0;
		end
	end
endmodule

module counter_dec_100(
	input clk, reset_p,
	input clk_time,
	output reg [3:0] digit_1, digit_10
	);

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit_1 = 0;
			digit_10 = 0;
		end
		else begin
			if (clk_time) begin
				if (digit_1 >= 9) begin 
					digit_1 = 0; //1의자리 10진 카운터

					if (digit_10 >= 9) digit_10 = 0; 
					else digit_10 = digit_10 + 1; //10의자리 1증가 59까지 카운트
				end
				else begin digit_1 = digit_1 + 1;
				end
			end
		end
	end
endmodule

module loadable_countdown_dec_60(
	input clk, reset_p,
	input clk_time,
	input load_enable,
	input [3:0] set_value_1, set_value_10,
	output reg [3:0] digit_1, digit_10
	);

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit_1 = 0;
			digit_10 = 0;
		end
		else begin
			//load_enable 1이면 set_value를 입력
			if (load_enable) begin
				digit_1 = set_value_1;
				digit_10 = set_value_10;
			end

			else if (clk_time) begin
				if (digit_1 <= 9)
					digit_1 = digit_1 - 1;
				else begin
					digit_1 = 9;
					digit_10 = digit_10 - 1;
					if (digit_10 <= 5) 
						digit_10 = 5;
				end
			end
		end
	end
endmodule


module loadable_countdown_dec_100(
	input clk, reset_p,
	input clk_time,
	input load_enable,
	input [3:0] set_value_1, set_value_10,
	output reg [3:0] digit_1, digit_10
	);

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit_1 = 0;
			digit_10 = 0;
		end
		else begin
			//load_enable 1이면 set_value를 입력
			if (load_enable) begin
				digit_1 = set_value_1;
				digit_10 = set_value_10;
			end

			else if (clk_time) begin
				if (digit_1 <= 9)
					digit_1 = digit_1 - 1;
				else begin
					digit_1 = 9;
					digit_10 = digit_10 - 1;
					if (digit_10 <= 9) 
						digit_10 = 9;
				end
			end
		end
	end
endmodule

module loadable_clock_min (
	input clk, reset_p,
	input clk_sec,
	input load_enable,
	input [3:0] set_value_1,
	input [3:0] set_value_10,
	output clock_min);

	reg [5:0] cnt;
	wire cp_min;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) cnt = 0;
		else begin
			if (load_enable) cnt = set_value_1 + (10 * set_value_10);
			else if (cnt > 59)  cnt = 0;		
			else if (clk_sec) cnt = cnt + 1;
		end
	end

	assign cp_min = (cnt < 30) ? 0 : 1;

	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_min),
		.n_edge(clock_min) );
endmodule


module load_count_up_N #(
	parameter N = 10 )(
	input clk, reset_p,
	input clk_time,
	input data_load,
	input [3:0] set_value,
	output reg [3:0] digit,
	output clk_over_flow_p );

	reg clk_over_flow;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit = 0;
			clk_over_flow = 0;
		end
		else begin
			if (data_load) begin
				digit = set_value;
			end
			else if (clk_time) begin
				if (digit >= (N-1)) begin 
					digit = 0; 
					clk_over_flow = 1;
				end
				else begin digit = digit + 1;
					clk_over_flow = 0;
				end
			end
		end
	end

	edge_detector_p ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(clk_over_flow),
		.p_edge(clk_over_flow_p) );
endmodule

module load_count_dn_N #(
	parameter N = 10 )(
	input clk, reset_p,
	input clk_time,
	input data_load,
	input [3:0] set_value,
	output reg [3:0] digit,
	output clk_under_flow_p );

	reg clk_under_flow;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit = 0;
			clk_under_flow = 0;
		end
		else begin
			if (data_load) begin
				digit = set_value;
			end
			else if (clk_time) begin
				digit = digit - 1;
				clk_under_flow = 0;
				if (digit > (N-1)) begin
					digit = (N-1);
					clk_under_flow = 1;
				end
			end
		end
	end

	edge_detector_p ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(clk_under_flow),
		.p_edge(clk_under_flow_p) );
endmodule

module load_count_ud_N #(
	parameter N = 10 )(
	input clk, reset_p,
	input clk_up,
	input clk_dn,
	input data_load,
	input [3:0] set_value,
	output reg [3:0] digit,
	output reg clk_over_flow,
	output reg clk_under_flow );

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			digit = 0;
			clk_over_flow = 0;
			clk_under_flow = 0;
		end
		else begin
			if (data_load) begin
				digit = set_value;
			end
			else if (clk_up) begin
				if (digit >= (N-1)) begin 
					digit = 0; 
					clk_over_flow = 1;
				end
				else begin digit = digit + 1;
				end
			end
			else if (clk_dn) begin
				digit = digit - 1;
				if (digit > (N-1)) begin
					digit = (N-1);
					clk_under_flow = 1;
				end
			end
			else begin 
				clk_over_flow = 0;
				clk_under_flow = 0;
			end
		end
	end
endmodule


module clk_set(
    input clk, reset_p,
    output clk_msec, clk_csec, clk_sec, clk_min);

    clock_usec usec_clk(clk, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_10 csec_clk(clk, reset_p, clk_msec, clk_csec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk, reset_p, clk_sec, clk_min);

endmodule