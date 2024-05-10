`timescale 1ns / 1ps


module buz (
	input clk, reset_p,
	input [6:0] melody_data,
	output reg buz_clk
	);

	parameter sys_freq = 125; // MHz

	parameter do_1_freq	   = 33;
	parameter do_s_1_freq  = 35;
	parameter re_1_freq	   = 37;
	parameter re_s_1_freq  = 39;
	parameter mi_1_freq	   = 41;
	parameter pa_1_freq	   = 44;
	parameter pa_s_1_freq  = 46;
	parameter so_1_freq	   = 49;
	parameter so_s_1_freq  = 52;
	parameter la_1_freq	   = 55;
	parameter la_s_1_freq  = 58;
	parameter ti_1_freq	   = 62;
	parameter do_2_freq	   = 65;
	parameter do_s_2_freq  = 69;
	parameter re_2_freq	   = 73;
	parameter re_s_2_freq  = 78;
	parameter mi_2_freq	   = 82;
	parameter pa_2_freq	   = 87;
	parameter pa_s_2_freq  = 92;
	parameter so_2_freq	   = 98;
	parameter so_s_2_freq  = 104;
	parameter la_2_freq	   = 110;
	parameter la_s_2_freq  = 117;
	parameter ti_2_freq	   = 123;

	parameter do_3_freq	   = 131;
	parameter do_s_3_freq  = 139;
	parameter re_3_freq	   = 147;
	parameter re_s_3_freq  = 156;
	parameter mi_3_freq	   = 165;
	parameter pa_3_freq	   = 175;
	parameter pa_s_3_freq  = 185;
	parameter so_3_freq	   = 196;
	parameter so_s_3_freq  = 208;
	parameter la_3_freq	   = 220;
	parameter la_s_3_freq  = 233;
	parameter ti_3_freq	   = 247;

	parameter do_4_freq	   = 262;
	parameter do_s_4_freq  = 277;
	parameter re_4_freq	   = 294;
	parameter re_s_4_freq  = 311;
	parameter mi_4_freq	   = 330;
	parameter pa_4_freq	   = 349;
	parameter pa_s_4_freq  = 370;
	parameter so_4_freq	   = 392;
	parameter so_s_4_freq  = 415;
	parameter la_4_freq	   = 440;
	parameter la_s_4_freq  = 466;
	parameter ti_4_freq	   = 494;

	parameter do_5_freq	   = 523;
	parameter do_s_5_freq  = 554;
	parameter re_5_freq	   = 587;
	parameter re_s_5_freq  = 622;
	parameter mi_5_freq	   = 659;
	parameter pa_5_freq	   = 698;
	parameter pa_s_5_freq  = 740;
	parameter so_5_freq	   = 784;
	parameter so_s_5_freq  = 831;
	parameter la_5_freq	   = 880;
	parameter la_s_5_freq  = 932;
	parameter ti_5_freq	   = 988;

	parameter do_6_freq	   = 1047;
	parameter do_s_6_freq  = 1109;
	parameter re_6_freq	   = 1175;
	parameter re_s_6_freq  = 1245;
	parameter mi_6_freq	   = 1319;
	parameter pa_6_freq	   = 1397;
	parameter pa_s_6_freq  = 1480;
	parameter so_6_freq	   = 1568;
	parameter so_s_6_freq  = 1661;
	parameter la_6_freq	   = 1760;
	parameter la_s_6_freq  = 1865;
	parameter ti_6_freq	   = 1976;

	parameter do_7_freq	   = 2093;
	parameter do_s_7_freq  = 2217;
	parameter re_7_freq	   = 2349;
	parameter re_s_7_freq  = 2489;
	parameter mi_7_freq	   = 2637;
	parameter pa_7_freq	   = 2794;
	parameter pa_s_7_freq  = 2960;
	parameter so_7_freq	   = 3136;
	parameter so_s_7_freq  = 3322;
	parameter la_7_freq	   = 3520;
	parameter la_s_7_freq  = 3729;
	parameter ti_7_freq	   = 3951;
	
	parameter do_8_freq	   = 4186;
	parameter do_s_8_freq  = 4435;
	parameter re_8_freq	   = 4699;
	parameter re_s_8_freq  = 4978;
	parameter mi_8_freq	   = 5274;
	parameter pa_8_freq	   = 5588;
	parameter pa_s_8_freq  = 5920;
	parameter so_8_freq	   = 6272;
	parameter so_s_8_freq  = 6645;
	parameter la_8_freq	   = 7040;
	parameter la_s_8_freq  = 7459;
	parameter ti_8_freq	   = 7902;

	parameter do_9_freq	   = 8372;
	parameter do_s_9_freq  = 8870;
	parameter re_9_freq	   = 9397;
	parameter re_s_9_freq  = 9956;
	parameter mi_9_freq	   = 10548;
	parameter pa_9_freq	   = 11175;
	parameter pa_s_9_freq  = 11840;
	parameter so_9_freq	   = 12544;
	parameter so_s_9_freq  = 13290;
	parameter la_9_freq	   = 14080;
	parameter la_s_9_freq  = 14917;
	parameter ti_9_freq	   = 15804;

	//  125MHz / 2^23 [22] = 29.802Hz
	//  125MHz / 2^22 [21] = 59.605Hz
	//	125MHz / 2^21 [20] = 119.209Hz
	//  125MHz / 2^20 [19] = 238.419Hz
	//  125MHz / 2^18 [17] = 476.837Hz
	//  125MHz / 2^17 [16] = 953.674Hz
	//  125MHz / 2^16 [15] = 1907.349Hz
	//  125MHz / 2^15 [14] = 3814.697Hz 
	//  125MHz / 2^14 [13] = 7629.394Hz
	// 	125MHz / 2^13 [12] = 15258.789Hz

	wire clk_usec_duty50;
	wire clk_msec_duty50;
	wire clk_usec_tick;

	clock_usec_duty50 #(sys_freq) clk_usec (
		.clk(clk),
		.reset_p(reset_p),
		.cp_usec(clk_usec_duty50),
		.clock_usec(clk_usec_tick) 
	);

	reg [13:0] freq;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			freq <= 0;
		end
		else begin
			case (melody_data)
				 0 : freq <= 1;
				 1 : freq <= do_1_freq;
				 2 : freq <= do_s_1_freq;
				 3 : freq <= re_1_freq;
				 4 : freq <= re_s_1_freq;
				 5 : freq <= mi_1_freq;
				 6 : freq <= pa_1_freq;
				 7 : freq <= pa_s_1_freq;
				 8 : freq <= so_1_freq;
				 9 : freq <= so_s_1_freq;
				10 : freq <= la_1_freq;
				11 : freq <= la_s_1_freq;
				12 : freq <= ti_1_freq;
				13 : freq <= do_2_freq;
				14 : freq <= do_s_2_freq;
				15 : freq <= re_2_freq;
				16 : freq <= re_s_2_freq;
				17 : freq <= mi_2_freq;
				18 : freq <= pa_2_freq;
				19 : freq <= pa_s_2_freq;
				20 : freq <= so_2_freq;
				21 : freq <= so_s_2_freq;
				22 : freq <= la_2_freq;
				23 : freq <= la_s_2_freq;
				24 : freq <= ti_2_freq;
				25 : freq <= do_3_freq;
				26 : freq <= do_s_3_freq;
				27 : freq <= re_3_freq;
				28 : freq <= re_s_3_freq;
				29 : freq <= mi_3_freq;
				30 : freq <= pa_3_freq;
				31 : freq <= pa_s_3_freq;
				32 : freq <= so_3_freq;
				33 : freq <= so_s_3_freq;
				34 : freq <= la_3_freq;
				35 : freq <= la_s_3_freq;
				36 : freq <= ti_3_freq;
				37 : freq <= do_4_freq;
				38 : freq <= do_s_4_freq;
				39 : freq <= re_4_freq;
				40 : freq <= re_s_4_freq;
				41 : freq <= mi_4_freq;
				42 : freq <= pa_4_freq;
				43 : freq <= pa_s_4_freq;
				44 : freq <= so_4_freq;
				45 : freq <= so_s_4_freq;
				46 : freq <= la_4_freq;
				47 : freq <= la_s_4_freq;
				48 : freq <= ti_4_freq;
				49 : freq <= do_5_freq;
				50 : freq <= do_s_5_freq;
				51 : freq <= re_5_freq;
				52 : freq <= re_s_5_freq;
				53 : freq <= mi_5_freq;
				54 : freq <= pa_5_freq;
				55 : freq <= pa_s_5_freq;
				56 : freq <= so_5_freq;
				57 : freq <= so_s_5_freq;
				58 : freq <= la_5_freq;
				59 : freq <= la_s_5_freq;
				60 : freq <= ti_5_freq;
				61 : freq <= do_6_freq;
				62 : freq <= do_s_6_freq;
				63 : freq <= re_6_freq;
				64 : freq <= re_s_6_freq;
				65 : freq <= mi_6_freq;
				66 : freq <= pa_6_freq;
				67 : freq <= pa_s_6_freq;
				68 : freq <= so_6_freq;
				69 : freq <= so_s_6_freq;
				70 : freq <= la_6_freq;
				71 : freq <= la_s_6_freq;
				72 : freq <= ti_6_freq;
				73 : freq <= do_7_freq;
				74 : freq <= do_s_7_freq;
				75 : freq <= re_7_freq;
				76 : freq <= re_s_7_freq;
				77 : freq <= mi_7_freq;
				78 : freq <= pa_7_freq;
				79 : freq <= pa_s_7_freq;
				80 : freq <= so_7_freq;
				81 : freq <= so_s_7_freq;
				82 : freq <= la_7_freq;
				83 : freq <= la_s_7_freq;
				84 : freq <= ti_7_freq;
				85 : freq <= do_8_freq;
				86 : freq <= do_s_8_freq;
				87 : freq <= re_8_freq;
				88 : freq <= re_s_8_freq;
				89 : freq <= mi_8_freq;
				90 : freq <= pa_8_freq;
				91 : freq <= pa_s_8_freq;
				92 : freq <= so_8_freq;
				93 : freq <= so_s_8_freq;
				94 : freq <= la_8_freq;
				95 : freq <= la_s_8_freq;
				96 : freq <= ti_8_freq;
				97 : freq <= do_9_freq;
				98 : freq <= do_s_9_freq;
				99 : freq <= re_9_freq;
				100: freq <= re_s_9_freq;
				101: freq <= mi_9_freq;
				102: freq <= pa_9_freq;
				103: freq <= pa_s_9_freq;
				104: freq <= so_9_freq;
				105: freq <= so_s_9_freq;
				106: freq <= la_9_freq;
				107: freq <= la_s_9_freq;
				108: freq <= ti_9_freq;				
				default: freq <= 1;
			endcase
		end
	end

	reg [18:0] freq_cnt;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin 
			buz_clk <= 0;
			freq_cnt <= 0;
		end
		else begin
			if (clk_usec_tick) begin
				freq_cnt <= freq_cnt + freq;
				if (freq_cnt > 500000) begin 
					freq_cnt <= 0;
					buz_clk <= ~buz_clk;
				end
			end
		end
	end
endmodule


module time_millis #(
	parameter sys_freq = 125 // MHz
	)(
	input clk, reset_p,
	output reg [31:0] millis
	);

	wire clk_usec_tick, clk_msec_tick;
	clock_usec #(sys_freq) clk_usec (.clk(clk),
									 .reset_p(reset_p),
									 .clock_usec(clk_usec_tick) );
	clock_div_1000 clk_msec (.clk(clk),
							 .reset_p(reset_p),
							 .clk_source(clk_usec_tick),
							 .clock_div_1000(clk_msec_tick) );

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			millis <= 0;
		end
		else begin
			if (clk_msec_tick) begin
				millis <= millis + 1;
			end
		end
	end
endmodule


module buz_test_top (
	input clk, reset_p,
	input [1:0] btn,
	output buz_clk
	);

	parameter C1  =   1;
	parameter Db1 =   2;
	parameter D1  =   3;
	parameter Eb1 =   4;
	parameter E1  =   5;
	parameter F1  =   6;
	parameter Gb1 =   7;
	parameter G1  =   8;
	parameter Ab1 =   9;
	parameter A1  =  10;
	parameter Bb1 =  11;
	parameter B1  =  12;

	parameter C2  =  13;
	parameter Db2 =  14;
	parameter D2  =  15;
	parameter Eb2 =  16;
	parameter E2  =  17;
	parameter F2  =  18;
	parameter Gb2 =  19;
	parameter G2  =  20;
	parameter Ab2 =  21;
	parameter A2  =  22;
	parameter Bb2 =  23;
	parameter B2  =  24;

	parameter C3  =  25;
	parameter Db3 =  26;
	parameter D3  =  27;
	parameter Eb3 =  28;
	parameter E3  =  29;
	parameter F3  =  30;
	parameter Gb3 =  31;
	parameter G3  =  32;
	parameter Ab3 =  33;
	parameter A3  =  34;
	parameter Bb3 =  35;
	parameter B3  =  36;
	
	parameter C4  =  37;
	parameter Db4 =  38;
	parameter D4  =  39;
	parameter Eb4 =  40;
	parameter E4  =  41;
	parameter F4  =  42;
	parameter Gb4 =  43;
	parameter G4  =  44;
	parameter Ab4 =  45;
	parameter A4  =  46;
	parameter Bb4 =  47;
	parameter B4  =  48;

	parameter C5  =  49;
	parameter Db5 =  50;
	parameter D5  =  51;
	parameter Eb5 =  52;
	parameter E5  =  53;
	parameter F5  =  54;
	parameter Gb5 =  55;
	parameter G5  =  56;
	parameter Ab5 =  57;
	parameter A5  =  58;
	parameter Bb5 =  59;
	parameter B5  =  60;

	parameter C6  =  61;
	parameter Db6 =  62;
	parameter D6  =  63;
	parameter Eb6 =  64;
	parameter E6  =  65;
	parameter F6  =  66;
	parameter Gb6 =  67;
	parameter G6  =  68;
	parameter Ab6 =  69;
	parameter A6  =  70;
	parameter Bb6 =  71;
	parameter B6  =  72;

	parameter C7  =  73;
	parameter Db7 =  74;
	parameter D7  =  75;
	parameter Eb7 =  76;
	parameter E7  =  77;
	parameter F7  =  78;
	parameter Gb7 =  79;
	parameter G7  =  80;
	parameter Ab7 =  81;
	parameter A7  =  82;
	parameter Bb7 =  83;
	parameter B7  =  84;

	parameter C8  =  85;
	parameter Db8 =  86;
	parameter D8  =  87;
	parameter Eb8 =  88;
	parameter E8  =  89;
	parameter F8  =  90;
	parameter Gb8 =  91;
	parameter G8  =  92;
	parameter Ab8 =  93;
	parameter A8  =  94;
	parameter Bb8 =  95;
	parameter B8  =  96;

	parameter C9  =  97;
	parameter Db9 =  98;
	parameter D9  =  99;
	parameter Eb9 = 100;
	parameter E9  = 101;
	parameter F9  = 102;
	parameter Gb9 = 103;
	parameter G9  = 104;
	parameter Ab9 = 105;
	parameter A9  = 106;
	parameter Bb9 = 107; 
	parameter B9  = 108;		

	reg [6:0]tone[373:0];
	reg [12:0]duration[373:0];
	reg [3:0] div = 2;
	always @* begin
		tone[   0] <= D4; 		   duration[   0] <= 125/div;
		tone[   1] <= 0;  		   duration[   1] <= 125/div;
		tone[   2] <= D4; 		   duration[   2] <= 125/div;
		tone[   3] <= 0;  		   duration[   3] <= 125/div;
		tone[   4] <= D5;		   duration[   4] <= 250/div;
		tone[   5] <= 0;		   duration[   5] <= 250/div;
		tone[   6] <= A4;		   duration[   6] <= 375/div;
		tone[   7] <= 0;		   duration[   7] <= 375/div;
		tone[   8] <= Ab4;		   duration[   8] <= 250/div;
		tone[   9] <= 0;		   duration[   9] <= 250/div;
		tone[  10] <= G4;		   duration[  10] <= 250/div;
		tone[  11] <= 0;		   duration[  11] <= 250/div;
		tone[  12] <= F4;		   duration[  12] <= 250/div;
		tone[  13] <= 0;		   duration[  13] <= 250/div;
		tone[  14] <= D4;		   duration[  14] <= 125/div;
		tone[  15] <= 0;		   duration[  15] <= 125/div;
		tone[  16] <= F4;		   duration[  16] <= 125/div;
		tone[  17] <= 0;		   duration[  17] <= 125/div;
		tone[  18] <= G4;		   duration[  18] <= 125/div;
		tone[  19] <= 0;		   duration[  19] <= 125/div;
		tone[  20] <= C4;		   duration[  20] <= 125/div;
		tone[  21] <= 0;		   duration[  21] <= 125/div;
		tone[  22] <= C4;		   duration[  22] <= 125/div;
		tone[  23] <= 0;		   duration[  23] <= 125/div;
		tone[  24] <= 0;		   duration[  24] <=   0/div; //skip
		tone[  25] <= 0;		   duration[  25] <=   0/div;
		tone[  26] <= 0;		   duration[  26] <=   0/div;
		tone[  27] <= 0;		   duration[  27] <=   0/div;
		tone[  28] <= D5;		   duration[  28] <= 250/div;
		tone[  29] <= 0;		   duration[  29] <= 250/div;
		tone[  30] <= A4;		   duration[  30] <= 375/div;
		tone[  31] <= 0;		   duration[  31] <= 375/div;
		tone[  32] <= Ab4;		   duration[  32] <= 250/div;
		tone[  33] <= 0;		   duration[  33] <= 250/div;
		tone[  34] <= G4;		   duration[  34] <= 250/div;
		tone[  35] <= 0;		   duration[  35] <= 250/div;
		tone[  36] <= F4;		   duration[  36] <= 250/div;
		tone[  37] <= 0;		   duration[  37] <= 250/div;
		tone[  38] <= D4;		   duration[  38] <= 125/div;
		tone[  39] <= 0;		   duration[  39] <= 125/div;
		tone[  40] <= F4;		   duration[  40] <= 125/div;
		tone[  41] <= 0;		   duration[  41] <= 125/div;
		tone[  42] <= G4;		   duration[  42] <= 125/div;
		tone[  43] <= 0;		   duration[  43] <= 125/div;
		tone[  44] <= B3;		   duration[  44] <= 125/div;
		tone[  45] <= 0;		   duration[  45] <= 125/div;
		tone[  46] <= B3;		   duration[  46] <= 125/div;
		tone[  47] <= 0;		   duration[  47] <= 125/div;
		tone[  48] <= D5;		   duration[  48] <= 250/div;
		tone[  49] <= 0;		   duration[  49] <= 250/div;
		tone[  50] <= A4;		   duration[  50] <= 375/div;
		tone[  51] <= 0;		   duration[  51] <= 375/div;
		tone[  52] <= Ab4;		   duration[  52] <= 250/div;
		tone[  53] <= 0;		   duration[  53] <= 250/div;
		tone[  54] <= G4;		   duration[  54] <= 250/div;
		tone[  55] <= 0;		   duration[  55] <= 250/div;
		tone[  56] <= F4;		   duration[  56] <= 250/div;
		tone[  57] <= 0;		   duration[  57] <= 250/div;
		tone[  58] <= D4;		   duration[  58] <= 125/div;
		tone[  59] <= 0;		   duration[  59] <= 125/div;
		tone[  60] <= F4;		   duration[  60] <= 125/div;
		tone[  61] <= 0;		   duration[  61] <= 125/div;
		tone[  62] <= G4;		   duration[  62] <= 125/div;
		tone[  63] <= 0;		   duration[  63] <= 125/div;
		tone[  64] <= 0;		   duration[  64] <=   0/div; //skip
		tone[  65] <= 0;		   duration[  65] <=   0/div;
		tone[  66] <= 0;		   duration[  66] <=   0/div;
		tone[  67] <= 0;		   duration[  67] <=   0/div;
		tone[  68] <= Bb3;		   duration[  68] <= 125/div; // 62 -> 125
		tone[  69] <= 0;		   duration[  69] <= 125/div; // 62 -> 125
		tone[  70] <= Bb3;		   duration[  70] <= 125/div; // 62 -> 125
		tone[  71] <= 0;		   duration[  71] <= 125/div; // 62 -> 125
		tone[  72] <= D5;		   duration[  72] <= 250/div;
		tone[  73] <= 0;		   duration[  73] <= 250/div;
		tone[  74] <= A4;		   duration[  74] <= 375/div;
		tone[  75] <= 0;		   duration[  75] <= 375/div;
		tone[  76] <= Ab4;		   duration[  76] <= 250/div;
		tone[  77] <= 0;		   duration[  77] <= 250/div;
		tone[  78] <= G4;		   duration[  78] <= 250/div;
		tone[  79] <= 0;		   duration[  79] <= 250/div;
		tone[  80] <= F4;		   duration[  80] <= 250/div;
		tone[  81] <= 0;		   duration[  81] <= 250/div;
		tone[  82] <= D4;		   duration[  82] <= 125/div;
		tone[  83] <= 0;		   duration[  83] <= 125/div;
		tone[  84] <= F4;		   duration[  84] <= 125/div;
		tone[  85] <= 0;		   duration[  85] <= 125/div;
		tone[  86] <= G4;		   duration[  86] <= 125/div;
		tone[  87] <= 0;		   duration[  87] <= 125/div;
		tone[  88] <= D5;  	       duration[  88] <= 125/div;
		tone[  89] <= 0;  		   duration[  89] <= 125/div;
		tone[  90] <= D5;  	       duration[  90] <= 125/div;//D5
		tone[  91] <= 0; 		   duration[  91] <= 125/div;
		tone[  92] <= D6;		   duration[  92] <= 250/div;//D6
		tone[  93] <= 0; 		   duration[  93] <= 250/div;
		tone[  94] <= A5;		   duration[  94] <= 375/div;//A5
		tone[  95] <= 0; 		   duration[  95] <= 375/div;
		tone[  96] <= Ab5;		   duration[  96] <= 250/div;//Ab5
		tone[  97] <= 0; 		   duration[  97] <= 250/div;
		tone[  98] <= G5;		   duration[  98] <= 250/div;//G5
		tone[  99] <= 0; 		   duration[  99] <= 250/div;
		tone[ 100] <= F5; 		   duration[ 100] <= 250/div;//F5
		tone[ 101] <= 0; 		   duration[ 101] <= 250/div;
		tone[ 102] <= D5; 		   duration[ 102] <= 125/div;//D5
		tone[ 103] <= 0; 		   duration[ 103] <= 125/div;
		tone[ 104] <= F5; 		   duration[ 104] <= 125/div;//F5
		tone[ 105] <= 0; 		   duration[ 105] <= 125/div;
		tone[ 106] <= G5; 		   duration[ 106] <= 125/div;//G5
		tone[ 107] <= 0; 		   duration[ 107] <= 125/div;
		tone[ 108] <= C5; 		   duration[ 108] <= 125/div;//C5
		tone[ 109] <= 0;  		   duration[ 109] <= 125/div;
		tone[ 110] <= C5; 		   duration[ 110] <= 125/div;//C5
		tone[ 111] <= 0;  		   duration[ 111] <= 125/div;
		tone[ 112] <= D6; 		   duration[ 112] <= 250/div;//D6
		tone[ 113] <= 0;  		   duration[ 113] <= 250/div;
		tone[ 114] <= A5; 		   duration[ 114] <= 375/div;//A5
		tone[ 115] <= 0;  		   duration[ 115] <= 375/div;
		tone[ 116] <= Ab5;		   duration[ 116] <= 250/div;//Ab5
		tone[ 117] <= 0;  		   duration[ 117] <= 250/div;
		tone[ 118] <= G5; 		   duration[ 118] <= 250/div;//G5
		tone[ 119] <= 0;  		   duration[ 119] <= 250/div;
		tone[ 120] <= F5; 		   duration[ 120] <= 250/div;//F5
		tone[ 121] <= 0;  		   duration[ 121] <= 250/div;
		tone[ 122] <= D5;  	       duration[ 122] <= 125/div;//D5
		tone[ 123] <= 0;  		   duration[ 123] <= 125/div;
		tone[ 124] <= F5;  	       duration[ 124] <= 125/div;//F5
		tone[ 125] <= 0;  		   duration[ 125] <= 125/div;
		tone[ 126] <= G5;  	       duration[ 126] <= 125/div;//G5
		tone[ 127] <= 0;  		   duration[ 127] <= 125/div;
		tone[ 128] <= B4;  	       duration[ 128] <= 125/div;//B4
		tone[ 129] <= 0;  		   duration[ 129] <= 125/div;
		tone[ 130] <= B4;  	       duration[ 130] <= 125/div;//B4
		tone[ 131] <= 0;  		   duration[ 131] <= 125/div;
		tone[ 132] <= D6;  	       duration[ 132] <= 250/div;//D6
		tone[ 133] <= 0;  		   duration[ 133] <= 250/div;
		tone[ 134] <= A5; 		   duration[ 134] <= 375/div;//A5
		tone[ 135] <= 0;  		   duration[ 135] <= 375/div;
		tone[ 136] <= Ab5;		   duration[ 136] <= 250/div;//Ab5
		tone[ 137] <= 0;  		   duration[ 137] <= 250/div;
		tone[ 138] <= G5; 		   duration[ 138] <= 250/div;//G5
		tone[ 139] <= 0;  		   duration[ 139] <= 250/div;
		tone[ 140] <= F5; 		   duration[ 140] <= 250/div;//F5
		tone[ 141] <= 0;  		   duration[ 141] <= 250/div;
		tone[ 142] <= D5; 		   duration[ 142] <= 125/div;//D5
		tone[ 143] <= 0;  		   duration[ 143] <= 125/div;
		tone[ 144] <= F5; 		   duration[ 144] <= 125/div;//F5
		tone[ 145] <= 0;  		   duration[ 145] <= 125/div;
		tone[ 146] <= G5; 		   duration[ 146] <= 125/div;//G5
		tone[ 147] <= 0;  		   duration[ 147] <= 125/div;
		tone[ 148] <= Bb4;		   duration[ 148] <= 125/div;//Bb4
		tone[ 149] <= 0;  		   duration[ 149] <= 125/div;
		tone[ 150] <= Bb4;		   duration[ 150] <= 125/div;//Bb4
		tone[ 151] <= 0;  		   duration[ 151] <= 125/div;
		tone[ 152] <= D6; 		   duration[ 152] <= 250/div;//D6
		tone[ 153] <= 0;  		   duration[ 153] <= 250/div;
		tone[ 154] <= A5; 		   duration[ 154] <= 375/div;//A5
		tone[ 155] <= 0;  		   duration[ 155] <= 375/div;
		tone[ 156] <= Ab5;		   duration[ 156] <= 250/div;//Ab5
		tone[ 157] <= 0;  		   duration[ 157] <= 250/div;
		tone[ 158] <= G5;		   duration[ 158] <= 250/div;//G5
		tone[ 159] <= 0;  		   duration[ 159] <= 250/div;
		tone[ 160] <= F5; 		   duration[ 160] <= 250/div;//F5
		tone[ 161] <= 0;  		   duration[ 161] <= 250/div;
		tone[ 162] <= D5; 		   duration[ 162] <= 125/div;//D5
		tone[ 163] <= 0;  		   duration[ 163] <= 125/div;
		tone[ 164] <= F5; 		   duration[ 164] <= 125/div;//F5
		tone[ 165] <= 0;  		   duration[ 165] <= 125/div;
		tone[ 166] <= G5; 		   duration[ 166] <= 125/div;//G5
		tone[ 167] <= 0;  		   duration[ 167] <= 125/div;
		tone[ 168] <= D5; 		   duration[ 168] <= 125/div;//D5
		tone[ 169] <= 0;  		   duration[ 169] <= 125/div;
		tone[ 170] <= D5; 		   duration[ 170] <= 125/div;//D5
		tone[ 171] <= 0;  		   duration[ 171] <= 125/div;
		tone[ 172] <= D6; 		   duration[ 172] <= 250/div;//D6
		tone[ 173] <= 0;  		   duration[ 173] <= 250/div;
		tone[ 174] <= A5; 		   duration[ 174] <= 375/div;//A5
		tone[ 175] <= 0;  		   duration[ 175] <= 375/div;
		tone[ 176] <= Ab5;		   duration[ 176] <= 250/div;//Ab5
		tone[ 177] <= 0;  		   duration[ 177] <= 250/div;
		tone[ 178] <= G5; 		   duration[ 178] <= 250/div;//G5
		tone[ 179] <= 0;  		   duration[ 179] <= 250/div;
		tone[ 180] <= F5; 		   duration[ 180] <= 250/div;//F5
		tone[ 181] <= 0;  		   duration[ 181] <= 250/div;
		tone[ 182] <= D5; 		   duration[ 182] <= 125/div;//D5
		tone[ 183] <= 0;  		   duration[ 183] <= 125/div;
		tone[ 184] <= F5; 		   duration[ 184] <= 125/div;//F5
		tone[ 185] <= 0;  		   duration[ 185] <= 125/div;
		tone[ 186] <= G5; 		   duration[ 186] <= 125/div;//G5
		tone[ 187] <= 0;  		   duration[ 187] <= 125/div;
		tone[ 188] <= C5; 		   duration[ 188] <= 125/div;//C5
		tone[ 189] <= 0;  		   duration[ 189] <= 125/div;
		tone[ 190] <= C5; 		   duration[ 190] <= 125/div;//C5
		tone[ 191] <= 0;  		   duration[ 191] <= 125/div;
		tone[ 192] <= D6; 		   duration[ 192] <= 250/div;//D6
		tone[ 193] <= 0;  		   duration[ 193] <= 250/div;
		tone[ 194] <= A5; 		   duration[ 194] <= 375/div;//A5
		tone[ 195] <= 0;  		   duration[ 195] <= 375/div;
		tone[ 196] <= Ab5;		   duration[ 196] <= 250/div;//Ab5
		tone[ 197] <= 0;  		   duration[ 197] <= 250/div;
		tone[ 198] <= G5; 		   duration[ 198] <= 250/div;//G5
		tone[ 199] <= 0;  		   duration[ 199] <= 250/div;
		tone[ 200] <= F5; 		   duration[ 200] <= 250/div;//F5
		tone[ 201] <= 0;  		   duration[ 201] <= 250/div;
		tone[ 202] <= D5;		   duration[ 202] <= 125/div;//D5
		tone[ 203] <= 0;  		   duration[ 203] <= 125/div;
		tone[ 204] <= F5; 		   duration[ 204] <= 125/div;//F5
		tone[ 205] <= 0;  		   duration[ 205] <= 125/div;
		tone[ 206] <= G5; 		   duration[ 206] <= 125/div;//G5
		tone[ 207] <= 0;  		   duration[ 207] <= 125/div;
		tone[ 208] <= B4; 		   duration[ 208] <= 125/div;//B4
		tone[ 209] <= 0;  		   duration[ 209] <= 125/div;
		tone[ 210] <= B4; 		   duration[ 210] <= 125/div;//B4
		tone[ 211] <= 0;  		   duration[ 211] <= 125/div;
		tone[ 212] <= D6; 		   duration[ 212] <= 250/div;//D6
		tone[ 213] <= 0;  		   duration[ 213] <= 250/div;
		tone[ 214] <= A5; 		   duration[ 214] <= 375/div;//A5
		tone[ 215] <= 0;  		   duration[ 215] <= 325/div;
		tone[ 216] <= Ab5;		   duration[ 216] <= 250/div;//Ab5
		tone[ 217] <= 0;  		   duration[ 217] <= 250/div;
		tone[ 218] <= G5; 		   duration[ 218] <= 250/div;//G5
		tone[ 219] <= 0;  		   duration[ 219] <= 250/div;
		tone[ 220] <= F5; 		   duration[ 220] <= 250/div;//F5
		tone[ 221] <= 0;  		   duration[ 221] <= 250/div;
		tone[ 222] <= D5; 		   duration[ 222] <= 125/div;//D5
		tone[ 223] <= 0;  		   duration[ 223] <= 125/div;
		tone[ 224] <= F5; 		   duration[ 224] <= 125/div;//F5
		tone[ 225] <= 0;  		   duration[ 225] <= 125/div;
		tone[ 226] <= G5; 		   duration[ 226] <= 125/div;//G5
		tone[ 227] <= 0;  		   duration[ 227] <= 125/div;
		tone[ 228] <= Bb4;		   duration[ 228] <= 125/div;//Bb4
		tone[ 229] <= 0;  		   duration[ 229] <= 125/div;
		tone[ 230] <= Bb4;		   duration[ 230] <= 125/div;//Bb4
		tone[ 231] <= 0;  		   duration[ 231] <= 125/div;
		tone[ 232] <= D6; 		   duration[ 232] <= 250/div;//D6
		tone[ 233] <= 0;  		   duration[ 233] <= 250/div;
		tone[ 234] <= A5; 		   duration[ 234] <= 375/div;//A5
		tone[ 235] <= 0;  		   duration[ 235] <= 375/div;
		tone[ 236] <= Ab5;		   duration[ 236] <= 250/div;//Ab5
		tone[ 237] <= 0;  		   duration[ 237] <= 250/div;
		tone[ 238] <= G5; 		   duration[ 238] <= 250/div;//G5
		tone[ 239] <= 0;  		   duration[ 239] <= 250/div;
		tone[ 240] <= F5; 		   duration[ 240] <= 250/div;//F5
		tone[ 241] <= 0;  		   duration[ 241] <= 250/div;
		tone[ 242] <= D5; 		   duration[ 242] <= 125/div;//D5
		tone[ 243] <= 0;  		   duration[ 243] <= 125/div;
		tone[ 244] <= F5; 		   duration[ 244] <= 125/div;//F5
		tone[ 245] <= 0;  		   duration[ 245] <= 125/div;
		tone[ 246] <= G5; 		   duration[ 246] <= 125/div;//G5
		tone[ 247] <= 0;  		   duration[ 247] <= 125/div;
		tone[ 248] <= F5;          duration[ 248] <= 250/div;                                                       
		tone[ 249] <= 0;           duration[ 249] <= 250/div;                                                 
		tone[ 250] <= F5;          duration[ 250] <= 125/div;                                                       
		tone[ 251] <= 0;           duration[ 251] <= 125/div;                                                 
		tone[ 252] <= F5;          duration[ 252] <= 125/div;                                                       
		tone[ 253] <= 0;           duration[ 253] <= 250/div;                                                 
		tone[ 254] <= F5;          duration[ 254] <= 250/div;                                                       
		tone[ 255] <= 0;           duration[ 255] <= 250/div;                                                 
		tone[ 256] <= F5;          duration[ 256] <= 250/div;                                                       
		tone[ 257] <= 0;           duration[ 257] <= 250/div;                                                 
		tone[ 258] <= D5;          duration[ 258] <= 250/div;                                                       
		tone[ 259] <= 0;           duration[ 259] <= 250/div;                                                 
		tone[ 260] <= D5;          duration[ 260] <= 625/div;                                                       
		tone[ 261] <= 0;           duration[ 261] <= 625/div;                                                 
		tone[ 262] <= F5;          duration[ 262] <= 250/div;                                                       
		tone[ 263] <= 0;           duration[ 263] <= 250/div;                                                 
		tone[ 264] <= F5;          duration[ 264] <= 125/div;                                                       
		tone[ 265] <= 0;           duration[ 265] <= 125/div;                                                 
		tone[ 266] <= F5;          duration[ 266] <= 125/div;                                                       
		tone[ 267] <= 0;           duration[ 267] <= 250/div;                                                 
		tone[ 268] <= G5;          duration[ 268] <= 250/div;                                                       
		tone[ 269] <= 0;           duration[ 269] <= 250/div;                                                 
		tone[ 270] <= Ab5;         duration[ 270] <= 250/div;                                                        
		tone[ 271] <= 0;           duration[ 271] <= 250/div;                                                 
		tone[ 272] <= G5;          duration[ 272] <=  42/div;                                                      
		tone[ 273] <= 0;           duration[ 273] <=  42/div;                                                 
		tone[ 274] <= Ab5;         duration[ 274] <=  42/div;                                                       
		tone[ 275] <= 0;           duration[ 275] <=  42/div;                                                 
		tone[ 276] <= G5;          duration[ 276] <=  42/div;                                                      
		tone[ 277] <= 0;           duration[ 277] <=  42/div;                                                 
		tone[ 278] <= F5;          duration[ 278] <= 125/div;                                                       
		tone[ 279] <= 0;           duration[ 279] <= 125/div;                                                 
		tone[ 280] <= D5;          duration[ 280] <= 125/div;                                                       
		tone[ 281] <= 0;           duration[ 281] <= 125/div;                                                 
		tone[ 282] <= F5;          duration[ 282] <= 125/div;                                                       
		tone[ 283] <= 0;           duration[ 283] <= 125/div;                                                 
		tone[ 284] <= G5;          duration[ 284] <= 125/div;                                                       
		tone[ 285] <= 0;           duration[ 285] <= 375/div;                                                 
		tone[ 286] <= F5;          duration[ 286] <= 250/div;                                                       
		tone[ 287] <= 0;           duration[ 287] <= 250/div;                                                 
		tone[ 288] <= F5;          duration[ 288] <= 125/div;                                                       
		tone[ 289] <= 0;           duration[ 289] <= 125/div;                                                 
		tone[ 290] <= F5;          duration[ 290] <= 125/div;                                                       
		tone[ 291] <= 0;           duration[ 291] <= 250/div;                                                 
		tone[ 292] <= G5;          duration[ 292] <= 250/div;                                                       
		tone[ 293] <= 0;           duration[ 293] <= 250/div;                                                 
		tone[ 294] <= Ab5;         duration[ 294] <= 125/div;                                                        
		tone[ 295] <= 0;           duration[ 295] <= 250/div;                                                 
		tone[ 296] <= A5;          duration[ 296] <= 250/div;                                                       
		tone[ 297] <= 0;           duration[ 297] <= 250/div;                                                 
		tone[ 298] <= C6;          duration[ 298] <= 250/div;                                                       
		tone[ 299] <= 0;           duration[ 299] <= 250/div;                                                 
		tone[ 300] <= A5;          duration[ 300] <= 375/div;                                                       
		tone[ 301] <= 0;           duration[ 301] <= 375/div;                                                 
		tone[ 302] <= D6;          duration[ 302] <= 250/div;                                                       
		tone[ 303] <= 0;           duration[ 303] <= 250/div;                                                 
		tone[ 304] <= D6;          duration[ 304] <= 250/div;                                                       
		tone[ 305] <= 0;           duration[ 305] <= 250/div;                                                 
		tone[ 306] <= D6;          duration[ 306] <= 125/div;                                                       
		tone[ 307] <= 0;           duration[ 307] <= 125/div;                                                 
		tone[ 308] <= A5;          duration[ 308] <= 125/div;                                                       
		tone[ 309] <= 0;           duration[ 309] <= 125/div;                                                 
		tone[ 310] <= D6;          duration[ 310] <= 125/div;                                                       
		tone[ 311] <= 0;           duration[ 311] <= 125/div;                                                 
		tone[ 312] <= C6;          duration[ 312] <= 625/div;                                                       
		tone[ 313] <= 0;           duration[ 313] <= 625/div;                                                 
		tone[ 314] <= G6;          duration[ 314] <= 500/div;                                                       
		tone[ 315] <= 0;           duration[ 315] <= 500/div;             /* L421  du du dudu dudu duu (intensifies) */  
		tone[ 316] <= A5;          duration[ 316] <= 250/div;                                             
		tone[ 317] <= 0;           duration[ 317] <= 250/div;                       
		tone[ 318] <= A5;          duration[ 318] <= 125/div;                                            
		tone[ 319] <= 0;           duration[ 319] <= 125/div;                       
		tone[ 320] <= A5;          duration[ 320] <= 125/div;                                            
		tone[ 321] <= 0;           duration[ 321] <= 250/div;                       
		tone[ 322] <= A5;          duration[ 322] <= 250/div;                                            
		tone[ 323] <= 0;           duration[ 323] <= 250/div;                       
		tone[ 324] <= A5;          duration[ 324] <= 250/div;                                            
		tone[ 325] <= 0;           duration[ 325] <= 250/div;                       
		tone[ 326] <= G5;          duration[ 326] <= 250/div;                                            
		tone[ 327] <= 0;           duration[ 327] <= 250/div;                       
		tone[ 328] <= G5;          duration[ 328] <= 625/div;                                            
		tone[ 329] <= 0;           duration[ 329] <= 625/div;                       
		tone[ 330] <= A5;          duration[ 330] <= 250/div;                                                
		tone[ 331] <= 0;           duration[ 331] <= 250/div;                       
		tone[ 332] <= A5;          duration[ 332] <= 125/div;                                            
		tone[ 333] <= 0;           duration[ 333] <= 125/div;                       
		tone[ 334] <= A5;          duration[ 334] <= 125/div;                                            
		tone[ 335] <= 0;           duration[ 335] <= 250/div;                       
		tone[ 336] <= A5;          duration[ 336] <= 250/div;                                            
		tone[ 337] <= 0;           duration[ 337] <= 250/div;                       
		tone[ 338] <= G5;          duration[ 338] <= 125/div;                                            
		tone[ 339] <= 0;           duration[ 339] <= 250/div;                       
		tone[ 340] <= A5;          duration[ 340] <= 250/div;                                            
		tone[ 341] <= 0;           duration[ 341] <= 250/div;                       
		tone[ 342] <= D6;          duration[ 342] <= 125/div;                                            
		tone[ 343] <= 0;           duration[ 343] <= 250/div;                       
		tone[ 344] <= A5;          duration[ 344] <= 125/div;                                            
		tone[ 345] <= 0;           duration[ 345] <= 125/div;                       
		tone[ 346] <= G5;          duration[ 346] <= 250/div;                                            
		tone[ 347] <= 0;           duration[ 347] <= 250/div;                       
		tone[ 348] <= D6;          duration[ 348] <= 250/div;                                            
		tone[ 349] <= 0;           duration[ 349] <= 250/div;                       
		tone[ 350] <= A5;          duration[ 350] <= 250/div;                                            
		tone[ 351] <= 0;           duration[ 351] <= 250/div;                       
		tone[ 352] <= G5;          duration[ 352] <= 250/div;                                            
		tone[ 353] <= 0;           duration[ 353] <= 250/div;                       
		tone[ 354] <= F5;          duration[ 354] <= 250/div;                                            
		tone[ 355] <= 0;           duration[ 355] <= 250/div;                       
		tone[ 356] <= C6;          duration[ 356] <= 250/div;                                            
		tone[ 357] <= 0;           duration[ 357] <= 250/div;                       
		tone[ 358] <= G5;          duration[ 358] <= 250/div;                                            
		tone[ 359] <= 0;           duration[ 359] <= 250/div;                       
		tone[ 360] <= F5;          duration[ 360] <= 250/div;                                            
		tone[ 361] <= 0;           duration[ 361] <= 250/div;                       
		tone[ 362] <= E5;          duration[ 362] <= 250/div;                                            
		tone[ 363] <= 0;           duration[ 363] <= 250/div;                       
		tone[ 364] <= Bb4;         duration[ 364] <= 250/div;                                             
		tone[ 365] <= 0;           duration[ 365] <= 250/div;                       
		tone[ 366] <= C5;          duration[ 366] <= 125/div;                                            
		tone[ 367] <= 0;           duration[ 367] <= 125/div;                       
		tone[ 368] <= D5;          duration[ 368] <= 125/div;                                            
		tone[ 369] <= 0;           duration[ 369] <= 250/div;                       
		tone[ 370] <= F5;          duration[ 370] <= 250/div;                                          
		tone[ 371] <= 0;           duration[ 371] <= 250/div;                       
		tone[ 372] <= C6;          duration[ 372] <= 1125/div;                                            
		tone[ 373] <= 0;           duration[ 373] <= 2125/div;                       

		//Epic part, L482

	end

	wire [31:0] current_time;
	reg [31:0] last_time;
	time_millis time_millis_inst (.clk(clk),
								  .reset_p(reset_p),
								  .millis(current_time) );	

	reg [6:0] melody_data;
	reg [8:0] i;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin 
			last_time <= 32'b0;
			i <= 0;
			melody_data <= tone[0];
		end
		else begin
			if (current_time - last_time >= duration[i]) begin
				last_time <= current_time;
				melody_data <= tone[i+1];
				i <= i + 1;
			end
		end
	end
	
	buz buz_module_0(clk, reset_p, melody_data, buz_clk);	

endmodule
