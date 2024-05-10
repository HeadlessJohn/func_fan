`timescale 1ns / 1ps

//직렬입력 직렬출력 serial in serial out
module shift_register_SISO_n (
    input clk, reset_p,
    input d,
    output q
    );
    
    reg [3:0] siso_reg;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) siso_reg <= 0;
        else begin //nonblocking 주의
            siso_reg[3] <= d;
            siso_reg[2] <= siso_reg[3];
            siso_reg[1] <= siso_reg[2];
            siso_reg[0] <= siso_reg[1];
        end        
    end

    assign q = siso_reg[0]; 

endmodule

//직렬입력 병렬출력 serial in parallel out
module shift_register_SIPO_n (
    input clk, reset_p,
    input d,
    input rd_en,
    output [3:0] q
    );

    reg [3:0] sipo_reg;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) sipo_reg <= 0;
        else begin //nonblocking 주의
            sipo_reg = {d, sipo_reg[3:1]}; //직렬입력 병렬출력
        end        
    end

    //4클럭 모두 입력 한 후 출력하도록
    //다른 메모리 읽을때 연결을 끊어 레이싱 상태를 방지
                            // == 4'bz      //re_en이 0이면 z 출력
    assign q = rd_en ? sipo_reg   : 4'bzzzz ; //rd_en이 1일때만 출력
          //출력, 입력, 제어
    // bufif1 (q[0], sipo_reg[0], rd_en); //rd_en 1이면 출력 0이면 Z출력
    // bufif1 (q[1], sipo_reg[1], rd_en);
    // bufif1 (q[2], sipo_reg[2], rd_en);
    // bufif1 (q[3], sipo_reg[3], rd_en);
endmodule


//병렬입력 직렬출력 parallel in serial out
module shift_register_PISO_n (
    input clk, reset_p,
    input [3:0] d,
    input shift_load, //1:직렬출력, 0:병렬입력
    output q
    );
 
    reg [3:0] piso_reg;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) piso_reg <= 0;
        else begin 
            if (shift_load) piso_reg <= {1'b0, piso_reg[3:1]}; //직렬출력
            else piso_reg <= d; //병렬입력
        end        
    end

    assign q = piso_reg[0]; //하위비트부터 출력 
    // 수신 받으려면 상위비트부터 채워서 하위비트 방향으로 시프트 시켜야함
endmodule


//병렬입력 병렬출력 parallel in parallel out
module shift_register_PIPO_p #(
    parameter N = 8
    ) (
    input clk, reset_p,
    input [N-1:0] d,
    input wr_en, rd_en, //wr_en 1 : 데이터 쓰기, rd_en 1 : 데이터 읽기
    output [N-1:0] q
    );
    
    reg [N-1:0] pipo_reg;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) pipo_reg <= 0;
        else if (wr_en) pipo_reg <= d; //wr_en 1일때만 쓸수 있도록
    end
    
    assign q = rd_en ? pipo_reg : 'bz; // rd_en 1일때만 출력, 0일때는 z출력
                                       // 'bz = zzzzzzzz... 모두 z일때 비트수 생략가능
endmodule

