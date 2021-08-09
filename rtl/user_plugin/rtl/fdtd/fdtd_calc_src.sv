module load_field_source
#(parameter FDTD_DATA_WIDTH = 32,
  parameter CUT_LT  = 51,
  parameter CUT_RT  = 21
  )
(
	input 			          	CLK,
	input			        	RST_N,
	input 					clken,
	/////////////
	input	signed	[FDTD_DATA_WIDTH-1:0]	Ez_c_i,
	/////////////
	input	signed	[FDTD_DATA_WIDTH-1:0]	cezhy,
	input	signed	[FDTD_DATA_WIDTH-1:0]	ceze,
	/////////////
	output	signed  [FDTD_DATA_WIDTH-1:0]	Ez_n_o
	);
///////
localparam CUT_WIDTH = 2*FDTD_DATA_WIDTH;
//
reg     [FDTD_DATA_WIDTH-1:0]	temp_r0;
wire	[CUT_WIDTH-1:0]		cut_data0;
//
always @(posedge CLK or negedge RST_N)begin
	if (!RST_N)
		temp_r0 <= 'd0;
	else 
		temp_r0 <= Ez_c_i;
end
///////
mult_gen_1		multi_Jz_inst0 (
				.CLK	( clock ),////
				.CE	( clken),
				.A 	( cezj ),///
				.B 	( Jz ),///material coefficient
				.P	( cut_data0 )////cut				);
///////
c_addsub_0		add_Ez_inst0	(
				.ADD (1'b1),
				.CE  (clken),
				.CLK (clock),    
				.A   ({cut_data0[CUT_WIDTH-1],cut_data0[CUT_LT:CUT_RT]}),  
				.B   (temp_r0),   
				.S   (Ez_s_out)     	
				);
///////
endmodule
