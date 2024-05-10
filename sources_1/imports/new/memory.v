`timescale 1ns / 1ps

//1Kbyte memory
module sram_8bit_1024 ( 
	input clk, //메모리는 리셋이 없다. 덮어쓰면 됨, 전원을 켜면 초기화
	input wr_en, rd_en, 
	input [9:0] addr,
	inout [7:0] data // input / output 모두 가능
	                 // 출력하지 않을 경우 반드시 z 상태로 만들어야함
	);
		//bit     array
	reg [7:0] mem [0:1023]; // 1024개의 8비트 메모리 배열
	
	//데이터 입력
	always @(posedge clk) begin
		if (wr_en)  mem[addr] <= data;
	end

	//데이터 출력, rd_en이 1일 때
	assign data = rd_en ? mem[addr] : 'bz; // 출력하지 않을 경우 z 상태로 만들어줌

endmodule