/*-----------------------------------------------//
//Module_name:fdtd_acc
//Version:
//Function_Description:
//Author: Emmet
//Time:
//-----------------------------------------------*/
`timescale 1ns/1ps

module fdtd_acc
#(
	parameter	FDTD_DATA_WIDTH 	= 32,
	parameter	TIME_STEPS      	= 50,
	parameter 	BUFFER_ADDR_WIDTH	= 6,
	parameter	REG_SIZE_WIDTH          = 16
	
)
(
	input 			        	        CLK,
	input			        	        RST_N,
	//start calculation flag
	input	logic 				        calc_Hy_flg_i,
	input	logic 				        calc_Ez_flg_i,
	input	logic 				        calc_src_flg_i,
        //data_mem -> ram_buffer
        //start buffer process  
	input 	logic      		        	buffer_Hy_start_i, 
	input   logic		    	        	buffer_Ez_start_i,
	input   logic		    	        	buffer_src_start_i,
	input   logic      		        	buffer_Hy_end_i,
	input   logic      		        	buffer_Ez_end_i, 
	input   logic      		        	buffer_src_end_i, 
	//
	input 			        	        buffer_end_i,  //end buffer process
	input 	logic   [FDTD_DATA_WIDTH-1:0]           buffer_size_i, //buffer size
	input					        wrtvalid_Hy_old_i,
	input					        wrtvalid_Ez_old_i,
	//fdtd calc coefficients
	input  	logic   signed   [FDTD_DATA_WIDTH-1:0]	ceze,	
	input  	logic   signed   [FDTD_DATA_WIDTH-1:0]	cezhy,	
	input  	logic   signed   [FDTD_DATA_WIDTH-1:0]	cezj,	
	input  	logic   signed   [FDTD_DATA_WIDTH-1:0]	chyh,	
	input  	logic   signed   [FDTD_DATA_WIDTH-1:0]	chyez,	
	input  	logic   signed   [FDTD_DATA_WIDTH-1:0]	coe0,
	//field source	
	input  	logic	signed   [FDTD_DATA_WIDTH-1:0]	Jz,	
	//previous timestep field_value
	input  	logic	signed   [FDTD_DATA_WIDTH-1:0]	Hy_old_i,
	input	logic	signed   [FDTD_DATA_WIDTH-1:0]	Ez_old_i,
	//current timestep field_value
	output 	logic   signed   [FDTD_DATA_WIDTH-1:0]	Hy_n_o,
	output 	logic   signed   [FDTD_DATA_WIDTH-1:0]	Ez_n_o,
	//ram_buffer -> data_mem
	//observation point data
	output	logic	[FDTD_DATA_WIDTH-1:0]	        sample_point_o,
	input	logic			                mem_rd_Hy_en_i,	
	input	logic			                mem_rd_Ez_en_i,	
	input	logic			                mem_rd_end_i,
	input	logic			                wrtvalid_sgl_i,	
	output	logic			        	wrt_Hy_start_o,
	output	logic			        	wrt_Ez_start_o,
	output	logic			        	wrt_src_start_o
);
//
logic			        rd_Hy_old_en;
logic			        rd_Ez_old_en;
logic			        wrt_Hy_n_en;
logic			        wrt_Ez_n_en;
//
logic				calc_Hy_en;
logic				calc_Ez_en;
logic				calc_src_en;
//
logic  [BUFFER_ADDR_WIDTH-1:0]  rd_Hy_old_addr;
logic  [BUFFER_ADDR_WIDTH-1:0]  rd_Ez_old_addr;
logic  [BUFFER_ADDR_WIDTH-1:0]  wrt_Ez_n_addr;
logic  [BUFFER_ADDR_WIDTH-1:0]  wrt_Hy_n_addr;
//
logic  [FDTD_DATA_WIDTH-1:0]	Hy_old;
logic  [FDTD_DATA_WIDTH-1:0]	Ez_old;
logic  [FDTD_DATA_WIDTH-1:0]	Hy_n;
logic  [FDTD_DATA_WIDTH-1:0]	Ez_n;
//
    fdtd_buffer 
    	#(     	.FDTD_DATA_WIDTH	( FDTD_DATA_WIDTH   ),
	       	.BUFFER_ADDR_WIDTH 	( BUFFER_ADDR_WIDTH ),
		.REG_SIZE_WIDTH  	( REG_SIZE_WIDTH    )
	)
	ram_buffer_inst
	(
		.CLK			( CLK		    ),
		.RST_N			( RST_N		    ),
		.buffer_size_i  	( buffer_size_i     ),
		//data_mem -> ram_buffer
		//buffer start and end
		.buffer_Hy_start_i	( buffer_Hy_start_i ),
		.buffer_Ez_start_i	( buffer_Ez_start_i ),
		.buffer_src_start_i	( buffer_src_start_i ),
		.buffer_Hy_end_i   	( buffer_Hy_end_i   ),
		.buffer_Ez_end_i   	( buffer_Ez_end_i   ),
		.buffer_src_end_i	( buffer_src_end_i   ),
		.wrtvalid_Hy_old_i	( wrtvalid_Hy_old_i ),
		.wrtvalid_Ez_old_i	( wrtvalid_Ez_old_i ),
		//ram_buffer -> data_mem
		.mem_rd_Hy_en_i		( mem_rd_Hy_en_i    ),
		.mem_rd_Ez_en_i		( mem_rd_Ez_en_i    ),
		.mem_rd_end_i		( mem_rd_end_i      ),
		.wrtvalid_sgl_i		( wrtvalid_sgl_i    ),
		//fdtd calculation
		.rd_Hy_old_en_i	   	( rd_Hy_old_en	    ),
		.rd_Ez_old_en_i	   	( rd_Ez_old_en	    ),
		.wrt_Hy_n_en_i		( wrt_Hy_n_en	    ),
		.wrt_Ez_n_en_i		( wrt_Ez_n_en	    ),
		//address
		.rd_Hy_old_addr_i 	( rd_Hy_old_addr    ),
		.rd_Ez_old_addr_i 	( rd_Ez_old_addr    ),
		.wrt_Hy_n_addr_i   	( wrt_Hy_n_addr     ),
		.wrt_Ez_n_addr_i   	( wrt_Ez_n_addr     ),
		//old data
		.Hy_old_i		( Hy_old_i	    ),
		.Ez_old_i		( Ez_old_i	    ),
		//participate calculation
		.Hy_old_o		( Hy_old	    ),
		.Ez_old_o		( Ez_old	    ),
		//new data
		.Hy_n_i			( Hy_n              ),
		.Ez_n_i			( Ez_n		    ),
		.Ez_n_o			( Ez_n_o	    ),
		.Hy_n_o			( Hy_n_o	    )
	);

//------------control calc process-----------//
    fdtd_calc_ctrl
    	#(
    		.TIME_STEPS   		(TIME_STEPS),
		.BUFFER_ADDR_WIDTH	(BUFFER_ADDR_WIDTH),
		.FDTD_DATA_WIDTH	(FDTD_DATA_WIDTH)
    	)
	fdtd_calc_ctrl_inst(
		.CLK			( CLK		    ),
		.RST_N			( RST_N		    ), 
		.buffer_size_i		( buffer_size_i	    ),
		//start calculation
		.calc_Hy_flg_i		( calc_Hy_flg_i     ),
		.calc_Ez_flg_i	        ( calc_Ez_flg_i     ),
		.calc_src_flg_i    	( calc_src_flg_i    ),
		//
		//generate calculation signal
	        .rd_Hy_old_en_o	        ( rd_Hy_old_en      ),
	        .rd_Ez_old_en_o	        ( rd_Ez_old_en      ),
		.wrt_Hy_n_en_o		( wrt_Hy_n_en       ),
		.wrt_Ez_n_en_o		( wrt_Ez_n_en       ),
		//calculation signal
		.calc_Hy_en_o		( calc_Hy_en	    ),
		.calc_Ez_en_o		( calc_Ez_en	    ),
		.calc_src_en_o		( calc_src_en       ),
		.rd_Hy_old_addr_o 	( rd_Hy_old_addr    ),
		.rd_Ez_old_addr_o 	( rd_Ez_old_addr    ),
		.wrt_Hy_n_addr_o   	( wrt_Hy_n_addr     ),
		.wrt_Ez_n_addr_o   	( wrt_Ez_n_addr     ),
		//ram_buffer -> data_mem
		.wrt_Hy_start_o		( wrt_Hy_start_o    ),	
		.wrt_Ez_start_o		( wrt_Ez_start_o    ),	
		.wrt_src_start_o	( wrt_src_start_o   )	
	);
//------------having fdtd calculation process-------//
    fdtd_calc_module
	#(
		.FDTD_DATA_WIDTH(FDTD_DATA_WIDTH)
	)
    	fdtd_calc_inst(
		.CLK		( CLK		),
		.RST_N		( RST_N		),
		//
		.calc_Hy_en_i	( calc_Hy_en	),
		.calc_Ez_en_i	( calc_Ez_en	),
		.calc_src_en_i	( calc_src_en	),
		//
		.ceze		( ceze          ),
		.cezhy		( cezhy         ),
		.cezj		( cezj         	),
		.chyh		( chyh        	),
		.chyez		( chyez         ),
		.coe0		( coe0          ),
		//
		.Jz		( Jz        	),
		//
		.Hy_old_i	( Hy_old	),
		.Ez_old_i	( Ez_old	),
		//
		.Hy_n_o		( Hy_n		),
		.Ez_n_o		( Ez_n		)
	);
endmodule
