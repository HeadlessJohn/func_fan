
module fan_timer(
    input clk, reset_p,
    input btn,
    input run_e,
    output reg alarm, 
    output reg [3:0] state,
    output timeout_pedge,
    output [19:0] cur_time,
    output [3:0] led_bar);
    
    parameter OFF          = 4'b0001;
    parameter ONE          = 4'b0010;
    parameter THREE        = 4'b0100;
    parameter FIVE         = 4'b1000;
    
    wire btn_pedge, btn_nedge;
    button_cntr ed0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_p_edge(btn_pedge), .btn_n_edge(btn_nedge));
    
    reg [3:0]next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = OFF;
        else state = next_state;
    end
    
    assign led_bar = state;
    
    reg clk_en;
    reg [3:0] set_value;
    assign clk_start = clk_en ? clk : 0;
    
    down_timer down(.clk(clk_start), .reset_p(reset_p), .load_enable(btn_nedge), .set_value(set_value), .cur_time(cur_time));
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= OFF;
        end
        else begin
            if (run_e) begin // fan_en이 활성화 되었을 때만 동작
                if (btn_pedge) begin
                    next_state <= {state[2:0], state[3]}; // state를 1비트씩 shift하여 다음 state로 이동
                end 
            end
            else begin // fan_en이 0인 경우 IDLE 상태로 이동- fan 멈춤
                next_state <= OFF;
            end
        end
    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            clk_en = 0;
        end
        else begin
            case(state)
            OFF:begin
                clk_en = 0;
            end
            ONE:begin
                clk_en = 1;
                set_value = 1;
            end
            THREE:begin
                set_value = 3;
            end
            FIVE:begin
                set_value = 5;
            end
            endcase
        end
    end

    always @(posedge clk or posedge reset_p)begin
        if(reset_p) alarm = 0;
        else begin
            if(cur_time==0) alarm = 1;
            else alarm = 0;
        end
    end

    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(alarm), .p_edge(timeout_pedge));

endmodule

module down_timer(
    input clk, reset_p,
    input load_enable,
    input [3:0] set_value,
    output [19:0] cur_time);
    
    wire clk_sec, clk_sec10, clk_min1, clk_min10, clk_hour;
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10, cur_hour;

    clk_set(clk, reset_p, clk_msec, clk_csec, clk_sec, clk_min);
   // assign clk_en = (cur_time == 0) ? 1'b0 : 1'b1;
  //  assign clk_sec_out = clk_en ? clk_sec : 0;
    
    load_count_ud_N #(10) sec1(.clk(clk), .reset_p(reset_p), .clk_dn(clk_sec),
        .data_load(load_enable), .set_value(0), .digit(cur_sec1), .clk_under_flow(clk_sec10));
    load_count_ud_N #(6) sec10(.clk(clk), .reset_p(reset_p), .clk_dn(clk_sec10),
        .data_load(load_enable), .set_value(set_value), .digit(cur_sec10), .clk_under_flow(clk_min1));
    load_count_ud_N #(10) min1(.clk(clk), .reset_p(reset_p), .clk_dn(clk_min1),
        .data_load(load_enable), .set_value(0), .digit(cur_min1), .clk_under_flow(clk_min10));
    load_count_ud_N #(6) min10(.clk(clk), .reset_p(reset_p), .clk_dn(clk_min10),
        .data_load(load_enable), .set_value(0), .digit(cur_min10), .clk_under_flow(clk_hour));
    load_count_ud_N #(10) hour(.clk(clk), .reset_p(reset_p), .clk_dn(clk_hour),
        .data_load(load_enable), .set_value(0), .digit(cur_hour), .clk_under_flow());
    
    assign cur_time = {cur_hour, cur_min10, cur_min1, cur_sec10, cur_sec1};
        
endmodule