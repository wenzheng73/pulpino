module load_field_source
#(parameter data_width = 64, parameter cut_width  = 128 )
(
	input 									clock,
	input									clken,
	/////////////
	input		signed	[data_width-1:0]	Ez_s_in,
	input		signed	[data_width-1:0]	Jz,
	/////////////
	//input		signed	[data_width-1:0]	Cezj,
	/////////////
	output		signed  [data_width-1:0]	Ez_s_out
				);
///////
localparam		Cezj = 32'b11111111111110011111100011101010;
///////
wire	[cut_width-1:0]		cut_data0;
///////
/*mult_gen_1					multi_Jz_inst0 (
								.CLK	( clock ),////
								.CE	    ( clken),
								.A 		( Cezj ),///
								.B 		( Jz ),///material coefficient
								.P		( cut_data0 )////cut处理
								);*/
mult_gen_1					multi_Jz_inst0 (
								//.CLK	( clock ),////
								//.CE	    ( clken),
								.A 		( Cezj ),///
								.B 		( Jz ),///material coefficient
								.P		( cut_data0 )////cut处理
								);
///////
c_addsub_1 					add_Ez_inst0	(
								//.ADD (1'b1),
								.CE	 (clken),
								.CLK (clock),    
								.A 	 ({cut_data0[cut_width-1],cut_data0[51:21]}),  
								.B	 (Ez_s_in),   
								.S	 (Ez_s_out)     	
								);
///////
endmodule
