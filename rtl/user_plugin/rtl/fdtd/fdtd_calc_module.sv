/*-----------------------------------------------//
//Module_name:fdtd_calc_module
//Version:
//Function_Description:
//Author: Emmet
//Time:
//-----------------------------------------------*/
`timescale 1ns/1ps

module fdtd_calc_module
#(	parameter	FDTD_DATA_WIDTH = 32,
	parameter	CUT_LT          = 51,
	parameter	CUT_RT          = 21
)
(
	input 			          	        CLK,
	input			        	        RST_N,
	//
	input  logic				        calc_Hy_en_i,
	input  logic				        calc_Ez_en_i,
	input  logic				        calc_src_en_i,
	input  logic signed	[FDTD_DATA_WIDTH-1:0]   ceze  ,	
        input  logic signed	[FDTD_DATA_WIDTH-1:0]	cezhy ,	
	input  logic signed	[FDTD_DATA_WIDTH-1:0]	cezj  ,	
	input  logic signed	[FDTD_DATA_WIDTH-1:0]	chyh  ,	
        input  logic signed	[FDTD_DATA_WIDTH-1:0]	chyez ,	
        input  logic signed	[FDTD_DATA_WIDTH-1:0]	coe0  ,	
        input  logic signed	[FDTD_DATA_WIDTH-1:0]	Jz    ,		
        input  logic signed	[FDTD_DATA_WIDTH-1:0]	Hy_old_i    ,	
        input  logic signed	[FDTD_DATA_WIDTH-1:0]	Ez_old_i    ,
	//
	output logic signed     [FDTD_DATA_WIDTH-1:0]	Hy_n_o,	
	output logic signed     [FDTD_DATA_WIDTH-1:0]	Ey_n_o	
);
logic [FDTD_DATA_WIDTH-1:0]	Ez_n_0;
logic [FDTD_DATA_WIDTH-1:0]	Ez_n_1;
//------updating magnetic data process---------//
fdtd_calc_Hy 
	#(
	  .FDTD_DATA_WIDTH ( FDTD_DATA_WIDTH ),
	  .CUT_LT	   ( CUT_LT ),
	  .CUT_RT	   ( CUT_RT )
	)
	calc_Hy_i(
	  .CLK           ( CLK          ),
	  .RST_N         ( RST_N        ),
	  //calculation signal 
	  .clken         ( calc_Hy_en_i ),
	  //coefficients
	  .chyh		 ( chyh         ),
          .chyez         ( chyez        ),
	  //previous field_data
	  .Hy_old_i	 ( Hy_old_i     ),
          .Ez_old_i      ( Ez_old_i     ),
	  //new field_data
	  .Hy_n_o        ( Hy_n_o       )
	);

//------updating electric data process--------//
fdtd_calc_Ez 
	#(
	  .FDTD_DATA_WIDTH ( FDTD_DATA_WIDTH ),
  	  .CUT_LT	   ( CUT_LT ),
	  .CUT_RT	   ( CUT_RT )
	)
	calc_Ez_i(
	  .CLK           ( CLK          ),
	  .RST_N         ( RST_N        ),
	  //calculation signal 
	  .clken         ( calc_Ez_en_i ),
	  //coefficients
	  .ceze		 ( ceze         ),
          .cezhy         ( cezhy        ),
	  //previous field_data
	  .Hy_old_i	 ( Hy_old_i     ),
          .Ez_old_i      ( Ez_old_i     ),
	  //new field_data
	  .Ez_n_o        ( Ez_n_0     )
	);

//------loading field source---------------//
fdtd_calc_src
	#(
	  .FDTD_DATA_WIDTH ( FDTD_DATA_WIDTH ),
  	  .CUT_LT	   ( CUT_LT ),
	  .CUT_RT	   ( CUT_RT )
	)
	calc_src_i(
	  .CLK           ( CLK          ),
	  .RST_N         ( RST_N        ),
	  //calculation signal
	  .clken         ( calc_src_en_i),
          //coefficients
	  .cezj		 ( cezj         ),
	  //source
          .Jz            ( Jz 		),
	  //current timestep's data
	  .Ez_c_i        ( Ez_old_i     ),
          //new data
	  .Ez_n_o        ( Ez_n_1     )
	
	);

//------data_select Ez-------------------//
fdtd_data_select 
	#(
	  .FDTD_DATA_WIDTH ( FDTD_DATA_WIDTH )
	)
	data_select_i
	(
          .CLK           ( CLK           ),
    	  .RST_N         ( RST_N         ),
  	  //select signal
	  .calc_Ez_en_i  ( calc_Ez_en_i  ),
	  .calc_src_en_i ( calc_src_en_i ),
          //input data	   
	  .Ez_n_0_i      ( Ez_n_0        ),
	  .Ez_n_1_i      ( Ez_n_1        ),
	  //output data
	  .Ez_n_o        ( Ez_n_o        )
	);
endmodule
