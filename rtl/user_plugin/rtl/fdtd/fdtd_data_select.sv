/*-----------------------------------------------//
//Module_name:fdtd_data_serlect
//Version:
//Function_Description:
//Author: Emmet
//Time:
//-----------------------------------------------*/

module fdtd_data_select 
#(parameter FDTD_DATA_WIDTH = 80)
(
	input 			          	        CLK,
	input			        	        RST_N,

	input 	logic			                calc_Ez_en_i,
	input 	logic					calc_src_en_i,
	/////
	input   logic	signed [FDTD_DATA_WIDTH-1:0]	Ez_n_0_i,//Ez_total
	input   logic	signed [FDTD_DATA_WIDTH-1:0]	Ez_n_1_i,//load_source


	/////
	output	logic   signed [FDTD_DATA_WIDTH-1:0]	Ez_n_o

	);

//
wire 	[1:0] 		    select0;

///////
assign	select0 = {calc_Ez_en_i,calc_src_en_i};
///////
always @(*)
	begin
		case(select0)
			2'b10: 	Ez_n_o = Ez_n_0_i;
			2'b01: 	Ez_n_o = Ez_n_1_i;
			default:Ez_n_o = 'b0;	
		endcase
	end	
//
endmodule 
