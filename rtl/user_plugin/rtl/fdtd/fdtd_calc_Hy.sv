module fdtd_calc_Hy

#(parameter FDTD_DATA_WIDTH = 32,
  parameter CUT_LT  = 51,
  parameter CUT_RT  = 21
  )
(
	input 			          	CLK,
	input			        	RST_N,
	input 					clken,
	/////////////
	input	signed	[FDTD_DATA_WIDTH-1:0]	Hy_old_i,
	input	signed	[FDTD_DATA_WIDTH-1:0]	Ez_old_i,
	/////////////
	input	signed	[FDTD_DATA_WIDTH-1:0]	chyez,
	input	signed	[FDTD_DATA_WIDTH-1:0]	Chyh,
	/////////////
	output	signed  [FDTD_DATA_WIDTH-1:0]	Hy_n_o
	);
//
localparam CUT_WIDTH = 2*FDTD_DATA_WIDTH;
////////////////////////////////////////////////////////
reg 	signed 	[FDTD_DATA_WIDTH-1:0]		Ez_temp0;
reg     signed 	[FDTD_DATA_WIDTH-1:0]		Ez_temp1;
wire 	signed 	[FDTD_DATA_WIDTH-1:0]		temp0;
/////////////////////////////////////////////////////////
wire	signed	[CUT_WIDTH-1:0]			cut_data0;
wire	signed	[CUT_WIDTH-1:0]			cut_data1;
/////////////////////////////////////////////////////////
wire 	signed 	[FDTD_DATA_WIDTH-1:0]		old_data;
/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////			
wire 	signed 	[FDTD_DATA_WIDTH-1:0]		chyez_0;
//
always @(posedge CLK or negedge RST_N)begin
	if (!RST_N)begin
	    Ez_temp0  <= 'd0;
	    Ez_temp1  <= 'd0;
	else begin
	    Ez_temp0  <= Ez_old_i;
	    Ez_temp1  <= Ez_temp0;
	end
end
//----------------------calc_Ez part--------------------//
c_addsub_0 	sub_Ez_inst0	(
			.ADD     (1'b0),
			.CE	 (clken),
			.CLK     (CLK),    
			.A 	 (Ez_temp0),  
			.B	 (Ez_temp1),   
			.S	 (temp0)     	
			);
/////////////////////////////////////////////////////
mult_gen_0	multi_Ez_inst0 (
			.CLK	( clock ),////
			.CE	( clken),
			.A	( temp0 ),///
			.B      ( chyez ),///material coefficient
			.P      ( cut_data0 )////cut
			);														
/////////								
mult_gen_0	multi_Ez_inst2 (
			.CLK    (clock ),////
			.CE	(clken),
			.A 	( Ez_0 ),///
			.B 	( chyh ),///material coefficient
			.P	( cut_data1 )////cut
			);
fdtd_data_delay
	#(FDTD_DATA_WIDTH = FDTD_DATA_WIDTH
	  DELAY_STAGE     = 2
	)
	u1(
		.data_i({cut_data0[CUT_WIDTH-1],cut_data0[CUT_LT:CUT_RT]}),
		.data_o(old_data)
	);
//////////////////////////////////////////////////////////////		
c_addsub_0 	add_Ez_inst3	(
			.ADD(1'b1 ),    // 
			.CE	(clken),     // 
			.CLK    (clock),  // 
			.A 	({cut_data0[CUT_WIDTH-1],cut_data0[CUT_LT:CUT_RT]}), 
			.B	(old_data),    // 
			.S	(Hy_n_o)      //	
			);	///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
endmodule
