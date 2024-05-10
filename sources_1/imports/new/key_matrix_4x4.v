`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module key_matrix_4x4(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value, //키가 눌린 16가지 경우
    output reg key_valid //아무 키도 눌리지 않은 경우
    );

    //링카운터 클록 분주기 8ms
    reg [19:0] clk_div; // 1라인당 8ms, 4라인 32ms
    always @(posedge clk) clk_div = clk_div + 1;
    //엣지 검출
    wire clk_1ms;
    edge_detector_n ed_clk_8ms(clk, reset_p, clk_div[16], clk_1ms_p, clk_1ms_n);

    //링카운터 
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) col = 4'b0001;
        //col과 key_valid가 같은 엣지에서 변화하면 col이 정지되지 않음
        //row가 0으로 인식되어 key_valid가 0이되어 키입력이 반복되는 문제 발생
        //col과 key_valid가 엇갈리게 변화되게 엣지 타이밍 조절해야 함
        else if(clk_1ms_p) begin//key_valid가 0일때 링카운터 돌아감
            if (!key_valid) begin
                case (col)
                    4'b0001 : col = 4'b0010;
                    4'b0010 : col = 4'b0100;
                    4'b0100 : col = 4'b1000;
                    4'b1000 : col = 4'b0001;
                    default : col = 4'b0001;
                endcase
            end
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            key_value = 0;
            key_valid = 0;
        end
        else begin
            if (clk_1ms_n) begin
                if(row) begin
                    key_valid = 1;
                    case ({col,row})
            /* S 1 */   8'b0001_0001 : key_value = 4'h7;   // 7
            /* S 2 */   8'b0001_0010 : key_value = 4'h8;   // 8
            /* S 3 */   8'b0001_0100 : key_value = 4'h9;   // 9
            /* S 4 */   8'b0001_1000 : key_value = 4'ha;   // +
            /* S 5 */   8'b0010_0001 : key_value = 4'h4;   // 4
            /* S 6 */   8'b0010_0010 : key_value = 4'h5;   // 5
            /* S 7 */   8'b0010_0100 : key_value = 4'h6;   // 6
            /* S 8 */   8'b0010_1000 : key_value = 4'hb;   // -
            /* S 9 */   8'b0100_0001 : key_value = 4'h1;   // 1
            /* S10 */   8'b0100_0010 : key_value = 4'h2;   // 2
            /* S11 */   8'b0100_0100 : key_value = 4'h3;   // 3
            /* S12 */   8'b0100_1000 : key_value = 4'he;   // x
            /* S13 */   8'b1000_0001 : key_value = 4'hc;   // clear 
            /* S14 */   8'b1000_0010 : key_value = 4'h0;   // 0
            /* S15 */   8'b1000_0100 : key_value = 4'hf;   // =
            /* S16 */   8'b1000_1000 : key_value = 4'hd;   // /
                        default : key_value = 0;
                    endcase   
                end
                else begin 
                    key_valid = 0;     
                    key_value = 0;
                end    
            end
        end
    end


endmodule


module key_matrix_4x4_seperate(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [15:0] key_value
    );

    //링카운터 클록 분주기 8ms
    reg [19:0] clk_div; // 1라인당 8ms, 4라인 32ms
    always @(posedge clk) clk_div = clk_div + 1;
    //엣지 검출
    wire clk_1ms;
    edge_detector_n ed_clk_1ms(clk, reset_p, clk_div[16], clk_1ms);

    //링카운터 
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) col = 4'b0001;
        else if(clk_1ms) begin
            case (col)
                4'b0001 : col = 4'b0010;
                4'b0010 : col = 4'b0100;
                4'b0100 : col = 4'b1000;
                4'b1000 : col = 4'b0001;
                default : col = 4'b0001;
            endcase
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) key_value = 0;
        else if (clk_1ms) begin
            case (col)
                4'b0001 : begin 
                    key_value[ 0] <= row[0] ? 1 : 0; // S1
                    key_value[ 1] <= row[1] ? 1 : 0; // S2 
                    key_value[ 2] <= row[2] ? 1 : 0; // S3 
                    key_value[ 3] <= row[3] ? 1 : 0; // S4 
                end
                4'b0010 : begin 
                    key_value[ 4] <= row[0] ? 1 : 0; // S5
                    key_value[ 5] <= row[1] ? 1 : 0; // S6
                    key_value[ 6] <= row[2] ? 1 : 0; // S7
                    key_value[ 7] <= row[3] ? 1 : 0; // S8
                end
                4'b0100 : begin 
                    key_value[ 8] <= row[0] ? 1 : 0; // S9
                    key_value[ 9] <= row[1] ? 1 : 0; // S10
                    key_value[10] <= row[2] ? 1 : 0; // S11
                    key_value[11] <= row[3] ? 1 : 0; // S12
                end
                4'b1000 : begin 
                    key_value[12] <= row[0] ? 1 : 0; // S13
                    key_value[13] <= row[1] ? 1 : 0; // S14
                    key_value[14] <= row[2] ? 1 : 0; // S15
                    key_value[15] <= row[3] ? 1 : 0; // S16
                end
                default : key_value <= key_value;
            endcase
        end
    end

endmodule


module keypad_cntr_FSM(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value,
    output reg key_valid
    );

    //5가지 상태 
    parameter SCAN_0      = 5'b00001;
    parameter SCAN_1      = 5'b00010;
    parameter SCAN_2      = 5'b00100;
    parameter SCAN_3      = 5'b01000;
    parameter KEY_PROCESS = 5'b10000;

    reg [2:0] state, next_state;


    //다음 상태로 전환
    //0-1-2-3-4-0
    //키 입력 감지시 KEY_PROCESS 상태로
    always @* begin
        case (state)
            SCAN_0 : begin
                if(row) next_state = KEY_PROCESS;
                else next_state = SCAN_1;
            end
            SCAN_1 : begin
                if(row) next_state = KEY_PROCESS;
                else next_state = SCAN_2;
            end
            SCAN_2 : begin
                if(row) next_state = KEY_PROCESS;
                else next_state = SCAN_3;
            end
            SCAN_3 : begin
                if(row) next_state = KEY_PROCESS;
                else next_state = SCAN_0;
            end
            KEY_PROCESS : begin
                if(row) next_state = KEY_PROCESS;
                else next_state = SCAN_0;
            end
        endcase
    end

    reg [19:0] clk_div;
    wire clk_8ms_n, clk_8ms_p;
    always @(posedge clk) clk_div = clk_div + 1;
    edge_detector_n ed_clk(clk, reset_p, clk_div[19], clk_8ms_p, clk_8ms_n);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) state = SCAN_0;
        else if(clk_8ms_p) state = next_state; //8ms마다 다음 상태로
    end 

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin 
            key_value = 0;
            key_valid = 0;
            col = 4'b0001;
        end
        else begin
            case (state)    
                SCAN_0 : begin col = 4'b0001; key_valid = 0; end
                SCAN_1 : begin col = 4'b0010; key_valid = 0; end                
                SCAN_2 : begin col = 4'b0100; key_valid = 0; end
                SCAN_3 : begin col = 4'b1000; key_valid = 0; end
                KEY_PROCESS : begin
                    key_valid = 1;
                    case ({col,row})
            /* S 1 */   8'b0001_0001 : key_value = 4'h7;   // 7
            /* S 2 */   8'b0001_0010 : key_value = 4'h8;   // 8
            /* S 3 */   8'b0001_0100 : key_value = 4'h9;   // 9
            /* S 4 */   8'b0001_1000 : key_value = 4'ha;   // +
            /* S 5 */   8'b0010_0001 : key_value = 4'h4;   // 4
            /* S 6 */   8'b0010_0010 : key_value = 4'h5;   // 5
            /* S 7 */   8'b0010_0100 : key_value = 4'h6;   // 6
            /* S 8 */   8'b0010_1000 : key_value = 4'hb;   // -
            /* S 9 */   8'b0100_0001 : key_value = 4'h1;   // 1
            /* S10 */   8'b0100_0010 : key_value = 4'h2;   // 2
            /* S11 */   8'b0100_0100 : key_value = 4'h3;   // 3
            /* S12 */   8'b0100_1000 : key_value = 4'he;   // x
            /* S13 */   8'b1000_0001 : key_value = 4'hc;   // clear 
            /* S14 */   8'b1000_0010 : key_value = 4'h0;   // 0
            /* S15 */   8'b1000_0100 : key_value = 4'hf;   // =
            /* S16 */   8'b1000_1000 : key_value = 4'hd;   // /
                        default : key_value = key_value;
                    endcase   
                end
            endcase
        end
    end
endmodule