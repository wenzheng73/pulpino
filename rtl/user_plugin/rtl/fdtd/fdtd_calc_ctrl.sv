/*-----------------------------------------------//
//Module_name:fdtd_calc_ctrl
//Version:
//Function_Description:
//Author: Emmet
//Time:
//-----------------------------------------------*/
`timescale 1ns/1ps

module fdtd_calc_ctrl
#(	
	parameter	BUFFER_ADDR_WIDTH	= 6  ,		
	parameter	FDTD_DATA_WIDTH         = 16 ,
	parameter	HY_PIPE_LEN		= 3  ,
	parameter	EZ_PIPE_LEN		= 3  ,
	parameter	SRC_PIPE_LEN		= 2  , 
	parameter	BUFFER_SIZE		= 50  
)
(
	input      				CLK,
	input      				RST_N,
	//calculation start signal
	input   logic   			calc_Hy_flg_i,
	input   logic   			calc_Ez_flg_i,
	input   logic   			calc_src_flg_i,
	//read/write address
	output	logic 	[BUFFER_ADDR_WIDTH-1:0] rd_Hy_old_addr_o, 
        output	logic	[BUFFER_ADDR_WIDTH-1:0] rd_Ez_old_addr_o,
        output	logic	[BUFFER_ADDR_WIDTH-1:0] wrt_Hy_n_addr_o, 
        output	logic	[BUFFER_ADDR_WIDTH-1:0] wrt_Ez_n_addr_o, 
        //calculation signal
	output  logic 				rd_Hy_old_en_o,
	output  logic 				rd_Ez_old_en_o,
	output  logic 				wrt_Hy_n_en_o,
	output  logic 				wrt_Ez_n_en_o,
	//
	output	logic				calc_Hy_en_o,
	output	logic				calc_Ez_en_o,
	output	logic				calc_src_en_o,

	//after finishing calculation,ram_buffer -> data_mem
	output	logic				wrt_Hy_start_o,
	output	logic				wrt_Ez_start_o,
	output	logic				wrt_src_start_o
);
//
logic [BUFFER_ADDR_WIDTH-1:0]	calc_num_cnt;
logic [BUFFER_ADDR_WIDTH-1:0]	rd_Hy_old_addr;
logic [BUFFER_ADDR_WIDTH-1:0]	rd_Ez_old_addr;
logic [BUFFER_ADDR_WIDTH-1:0]	wrt_Hy_n_addr;
logic [BUFFER_ADDR_WIDTH-1:0]	wrt_Ez_n_addr;
logic 				calc_Hy_en;
logic 				calc_Ez_en;
logic 				calc_src_en;
logic 				calc_Hy_end_flg;
logic 				calc_Ez_end_flg;
logic 				rd_Hy_old_en;
logic 				rd_Hy_old_en_r;
logic 				rd_Ez_old_en;
logic 				rd_Ez_old_en_r;
logic 				wrt_Hy_n_en;
logic 				wrt_Ez_n_en;
logic 				wrt_Hy_start;
logic 				wrt_Ez_start;
logic 				wrt_src_start;

//
enum logic [3:0] {	IDLE,
			CALC_HY,
			WAIT_HY_END,
			CALC_EZ,
			WAIT_EZ_END,
			LOAD_SRC,
			WAIT_SRC_END
		} CS_CALC,NS_CALC;
//
assign	calc_Hy_end_flg  = (calc_num_cnt == BUFFER_SIZE-1'b1) ? 1'b1 :1'b0;
assign	calc_Ez_end_flg  = (calc_num_cnt == BUFFER_SIZE-1'b1) ? 1'b1 :1'b0;
assign  rd_Hy_old_addr_o = rd_Hy_old_addr ;
assign  rd_Ez_old_addr_o = rd_Ez_old_addr ;
assign  wrt_Hy_n_addr_o  = wrt_Hy_n_addr  ;
assign  wrt_Ez_n_addr_o  = wrt_Ez_n_addr  ; 
//
assign  rd_Hy_old_en_o   = (CS_CALC == CALC_HY) ? rd_Hy_old_en_r : (rd_Hy_old_en || rd_Hy_old_en_r)  ;   
assign  rd_Ez_old_en_o   = (CS_CALC == CALC_EZ) ? rd_Ez_old_en_r : (rd_Ez_old_en || rd_Ez_old_en_r ) ;
assign  wrt_Hy_n_en_o    = wrt_Hy_n_en ;
assign  wrt_Ez_n_en_o    = (CS_CALC == WAIT_SRC_END) ? 1'b1 : wrt_Ez_n_en ;
//
assign  calc_Hy_en_o     = calc_Hy_en     ;
assign  calc_Ez_en_o     = calc_Ez_en     ;
assign  calc_src_en_o    = calc_src_en    ;
//
assign  wrt_Hy_start_o   = wrt_Hy_start   ;
assign  wrt_Ez_start_o   = wrt_Ez_start   ;
assign  wrt_src_start_o  = wrt_src_start  ;


//
logic [5:0]	pipe_dly_cnt;
//
always_ff @(posedge CLK or negedge RST_N)
	begin
	if (!RST_N)
		CS_CALC <= IDLE;
	else 
		CS_CALC <= NS_CALC;
	end
//
always_comb
	begin	
		case (CS_CALC)
		IDLE:	begin   
				if (calc_Hy_flg_i)
					NS_CALC = CALC_HY;
				else if (calc_Ez_flg_i)
					NS_CALC = CALC_EZ;
				else if (calc_src_flg_i)
					NS_CALC = LOAD_SRC;
				else
					NS_CALC = IDLE;
			end

		CALC_HY:
			begin
				if (calc_Hy_end_flg)begin
					NS_CALC = WAIT_HY_END;
				end
				else begin
					NS_CALC = CALC_HY;
				end
			end
		WAIT_HY_END:begin
				if (pipe_dly_cnt == HY_PIPE_LEN)
					NS_CALC = IDLE;
				else
					NS_CALC = WAIT_HY_END;
			end	
		CALC_EZ:
			begin
				if (calc_Ez_end_flg)begin
					NS_CALC = WAIT_EZ_END;
				end
				else begin
					NS_CALC = CALC_EZ;
				end
			end
		WAIT_EZ_END:begin
				if (pipe_dly_cnt == EZ_PIPE_LEN)
					NS_CALC = IDLE;
				else
					NS_CALC = WAIT_EZ_END;
			end	
		LOAD_SRC:begin
				if (pipe_dly_cnt == SRC_PIPE_LEN)
					NS_CALC = WAIT_SRC_END;
				else
					NS_CALC = LOAD_SRC;
			end	
		WAIT_SRC_END:begin
				NS_CALC = IDLE;
			end
		default: NS_CALC = IDLE;
		endcase
	end
//---------some counters of controling calculation process-----------//
//set pipeline signal
always_ff @(posedge CLK or negedge RST_N)
	begin
		if (!RST_N)begin
			pipe_dly_cnt <= 'd0;
		end
		else if (CS_CALC == WAIT_HY_END)begin
			if (pipe_dly_cnt == HY_PIPE_LEN)
				pipe_dly_cnt <= 'd0;
			else 
				pipe_dly_cnt <= pipe_dly_cnt + 1'b1;
		end
		else if (CS_CALC == WAIT_EZ_END)begin
			if (pipe_dly_cnt == EZ_PIPE_LEN)
				pipe_dly_cnt <= 'd0;
			else
				pipe_dly_cnt <= pipe_dly_cnt + 1'b1;
		end
		else if (CS_CALC == LOAD_SRC)begin
			if (pipe_dly_cnt == SRC_PIPE_LEN)
				pipe_dly_cnt <= 'd0;
			else
				pipe_dly_cnt <= pipe_dly_cnt + 1'b1;
		end
		else 
			pipe_dly_cnt <= 'd0;
	end
//
always_ff @(posedge CLK, negedge RST_N)
	begin
		if (!RST_N)
			calc_num_cnt <= 'd0;
		else if (CS_CALC == CALC_HY)
			calc_num_cnt <= (calc_num_cnt == BUFFER_SIZE-1'b1) ? 'd0 : calc_num_cnt + 1'b1;
		else if (CS_CALC == CALC_EZ)
			calc_num_cnt <= (calc_num_cnt == BUFFER_SIZE-1'b1) ? 'd0 : calc_num_cnt + 1'b1;
		else
			calc_num_cnt <=  'd0;
	end
//
always_ff @(posedge CLK or negedge RST_N)
	begin
		if (!RST_N)begin
			wrt_Hy_start    <= 1'b0;
			wrt_Ez_start    <= 1'b0;
			wrt_src_start   <= 1'b0;
		end
		else case(NS_CALC)
		IDLE:begin
			wrt_Hy_start <= 1'b0;wrt_Ez_start <= 1'b0;wrt_src_start <= 1'b0;
		end
		CALC_HY:begin
			wrt_Hy_start <= 1'b0;wrt_Ez_start <= 1'b0;wrt_src_start <= 1'b0;
		end
		WAIT_HY_END:begin
			wrt_Hy_start <= 1'b1;wrt_Ez_start <= 1'b0;wrt_src_start <= 1'b0;
		end
		CALC_EZ:begin
			wrt_Hy_start <= 1'b0;wrt_Ez_start <= 1'b0;wrt_src_start <= 1'b0;
		end
		WAIT_EZ_END:begin
			wrt_Hy_start <= 1'b0;wrt_Ez_start <= 1'b1;wrt_src_start <= 1'b0;
		end
		LOAD_SRC:begin
			wrt_Hy_start <= 1'b0;wrt_Ez_start <= 1'b0;wrt_src_start <= 1'b0;
		end
		WAIT_SRC_END:begin
			wrt_Hy_start <= 1'b0;wrt_Ez_start <= 1'b0;wrt_src_start <= 1'b1;
		end
		default:begin
			wrt_Hy_start <= 1'b0;wrt_Ez_start <= 1'b0;wrt_src_start <= 1'b0;
		end
		endcase
	end
//--------generate read/write enable signal of RAM----------//
always_comb
	begin
             if (!RST_N)begin
	             rd_Hy_old_en = 1'b0;  rd_Ez_old_en = 1'b0;
	     end
	     else case(CS_CALC)
             IDLE: begin
		     rd_Hy_old_en = 1'b0;  rd_Ez_old_en = 1'b0;
		   end

             CALC_HY: begin
		     rd_Hy_old_en = 1'b1;  rd_Ez_old_en = 1'b1;
		   end
	     
	     WAIT_HY_END: begin
		     rd_Hy_old_en = 1'b0;  rd_Ez_old_en = 1'b0;
		   end

	     CALC_EZ: begin
		     rd_Hy_old_en = 1'b1;  rd_Ez_old_en = 1'b1;
		   end

	     WAIT_EZ_END: begin
		     rd_Hy_old_en = 1'b0;  rd_Ez_old_en = 1'b0;
		   end

	     LOAD_SRC: begin
		     rd_Hy_old_en = 1'b1;  rd_Ez_old_en = 1'b1;
		   end

	     WAIT_SRC_END: begin
		     rd_Hy_old_en = 1'b0;  rd_Ez_old_en = 1'b0;
		   end

	     default:begin
		     rd_Hy_old_en = 1'b0;  rd_Ez_old_en = 1'b0;
		   end
	     endcase
     end
//
always_ff @(posedge CLK ,negedge RST_N)begin
	if (!RST_N)
          rd_Ez_old_en_r <= 1'b0;
        else 
	  rd_Ez_old_en_r <= rd_Ez_old_en;
end
//
always_ff @(posedge CLK ,negedge RST_N)begin
	if (!RST_N)
          rd_Hy_old_en_r <= 1'b0;
	else  
	  rd_Hy_old_en_r <= rd_Hy_old_en;
end
//
//--------generate driving signal of mem_ctrl module--------//
//delay signal Hy's writing
logic                           wrt_Hy_n_en_r0;
logic                           wrt_Hy_n_en_r1;
logic                           wrt_Hy_n_en_r2;
logic                           wrt_Hy_n_en_r3;
//delay signal Ez's writing
logic                           wrt_Ez_n_en_r0;
logic                           wrt_Ez_n_en_r1;
logic                           wrt_Ez_n_en_r2;
logic                           wrt_Ez_n_en_r3;
//
always_ff @(posedge CLK ,negedge RST_N)
	begin
		if (!RST_N)begin
        	        wrt_Hy_n_en_r0  <= 1'b0;   
        	        wrt_Ez_n_en_r0  <= 1'b0;
                        calc_Hy_en      <= 1'b0;  
			calc_Ez_en      <= 1'b0;
			calc_src_en     <= 1'b0;
		end
		else case(CS_CALC)
		IDLE:	begin
				wrt_Hy_n_en_r0  <= 1'b0; wrt_Ez_n_en_r0  <= 1'b0;
                                calc_Hy_en      <= 1'b0; calc_Ez_en      <= 1'b0;
				calc_src_en     <= 1'b0;
			end
		CALC_HY:begin
				wrt_Hy_n_en_r0  <= 1'b1; wrt_Ez_n_en_r0  <= 1'b0;
                                calc_Hy_en      <= 1'b1; calc_Ez_en      <= 1'b0;
				calc_src_en     <= 1'b0;
			end

		WAIT_HY_END:begin
				wrt_Hy_n_en_r0  <= 1'b0; wrt_Ez_n_en_r0  <= 1'b0;
                                calc_Hy_en      <= 1'b1; calc_Ez_en      <= 1'b0;
				calc_src_en     <= 1'b0;
			end

		CALC_EZ:begin
				wrt_Hy_n_en_r0  <= 1'b0; wrt_Ez_n_en_r0  <= 1'b1;
                                calc_Hy_en      <= 1'b0; calc_Ez_en      <= 1'b1;
				calc_src_en     <= 1'b0;
			end

		WAIT_EZ_END:begin
				wrt_Hy_n_en_r0  <= 1'b0; wrt_Ez_n_en_r0  <= 1'b0;
                                calc_Hy_en      <= 1'b0; calc_Ez_en      <= 1'b1;
				calc_src_en     <= 1'b0;
			end

		LOAD_SRC:begin
				wrt_Hy_n_en_r0  <= 1'b0; wrt_Ez_n_en_r0  <= 1'b0;
                                calc_Hy_en      <= 1'b0; calc_Ez_en      <= 1'b0;
				calc_src_en     <= 1'b1;
			end

		WAIT_SRC_END:begin
				wrt_Hy_n_en_r0  <= 1'b0; wrt_Ez_n_en_r0  <= 1'b0;
                                calc_Hy_en      <= 1'b0; calc_Ez_en      <= 1'b0;
				calc_src_en     <= 1'b1;
			end

		default:begin
				wrt_Hy_n_en_r0  <= 1'b0; wrt_Ez_n_en_r0  <= 1'b0;
                                calc_Hy_en      <= 1'b0; calc_Ez_en      <= 1'b0;
				calc_src_en     <= 1'b0;
			end

		endcase
	end
//
always_ff @(posedge CLK, negedge RST_N)
	begin
		if (!RST_N)begin
			wrt_Hy_n_en    <= 1'b0;
			wrt_Hy_n_en_r1 <= 1'b0;
			wrt_Hy_n_en_r2 <= 1'b0;
			wrt_Hy_n_en_r3 <= 1'b0;
		end
		else begin
	                wrt_Hy_n_en_r1 <= wrt_Hy_n_en_r0;
	                wrt_Hy_n_en_r2 <= wrt_Hy_n_en_r1;
                        wrt_Hy_n_en_r3 <= wrt_Hy_n_en_r2;
                        wrt_Hy_n_en    <= wrt_Hy_n_en_r3;
		end
	end
//
always_ff @(posedge CLK, negedge RST_N)
	begin
		if (!RST_N)begin
			wrt_Ez_n_en    <= 1'b0;
			wrt_Ez_n_en_r1 <= 1'b0;
			wrt_Ez_n_en_r2 <= 1'b0;
			wrt_Ez_n_en_r3 <= 1'b0;
		end
		else begin
	                wrt_Ez_n_en_r1 <= wrt_Ez_n_en_r0;
	                wrt_Ez_n_en_r2 <= wrt_Ez_n_en_r1;
	                wrt_Ez_n_en_r3 <= wrt_Ez_n_en_r2;
	                wrt_Ez_n_en    <= wrt_Ez_n_en_r3;
		end
	end
    /*fdtd_data_delay 
                   #(
		       .DATA_WIDTH  ( 1                ),
		       .DELAY_STAGE ( HY_PIPE_LEN+1'b1 )
		   )
		   delay_wrt_Hy_en_i(
		       .CLK         ( CLK            ),
		       .RST_N       ( RST_N          ),
		       .data_i      ( wrt_Hy_n_en_r0 ),
		       .data_o      ( wrt_Hy_n_en    )
		   );
    fdtd_data_delay 
                   #(
		       .DATA_WIDTH  ( 1                ),
		       .DELAY_STAGE ( EZ_PIPE_LEN+1'b1 )
		   )
		   delay_wrt_Ez_en_i(
		       .CLK         ( CLK            ),
		       .RST_N       ( RST_N          ),
		       .data_i      ( wrt_Ez_n_en_r0 ),
		       .data_o      ( wrt_Ez_n_en    )
		   );*/

//--------generate Hy's reading address of RAM--------------//
logic [BUFFER_ADDR_WIDTH-1:0] rd_Hy_old_addr_r0;

always_ff @(posedge CLK, negedge RST_N)	
	begin
		if (!RST_N)begin
            		rd_Hy_old_addr <= 'd0;
                        rd_Hy_old_addr_r0 <= 'd0;
		end
		else if (CS_CALC == IDLE)begin
                        rd_Hy_old_addr <= 'd0;
                        rd_Hy_old_addr_r0 <= 'd0;
	        end
		else if (CS_CALC == CALC_HY)begin
			rd_Hy_old_addr_r0 <= rd_Hy_old_addr_r0 + 1'b1;
                        rd_Hy_old_addr <= rd_Hy_old_addr_r0;
		end
                else if (CS_CALC == CALC_EZ)begin
			rd_Hy_old_addr <= rd_Hy_old_addr + 1'b1;
                end
		else begin
			rd_Hy_old_addr <= 'd0;
			rd_Hy_old_addr_r0 <= 'd0;
		end

	end
//--------generate Ez's reading address of RAM--------------//
logic [BUFFER_ADDR_WIDTH-1:0] rd_Ez_old_addr_r0;

always_ff @(posedge CLK, negedge RST_N)	
	begin
		if (!RST_N)begin
            	 	rd_Ez_old_addr <= 'd0;	
                        rd_Ez_old_addr_r0 <= 'd0;
		end
                else if (CS_CALC == IDLE)begin
	            	rd_Ez_old_addr <= 'd0;	
                        rd_Ez_old_addr_r0 <= 'd0;        
		end
                else if (CS_CALC == CALC_HY)begin
			rd_Ez_old_addr <= rd_Ez_old_addr + 1'b1;
		end
		else if (CS_CALC == CALC_EZ)begin
			rd_Ez_old_addr_r0 <= rd_Ez_old_addr_r0 + 1'b1;
			rd_Ez_old_addr <= rd_Ez_old_addr_r0;
		end
		else if (CS_CALC == LOAD_SRC)
			rd_Ez_old_addr <= 'd0;
		else begin
			rd_Ez_old_addr <= 'd0;
			rd_Ez_old_addr_r0 <= 'd0;
		end
	end
//---------------delay address of writing-------------------//-------
always_ff @(posedge CLK, negedge RST_N )
	begin
		if (!RST_N)begin
			wrt_Hy_n_addr <= 'd0;
		end
		else begin
			wrt_Hy_n_addr <= wrt_Hy_n_en ? (wrt_Hy_n_addr + 1'b1) : 1'b0;	
		end
	end
//
always_ff @(posedge CLK, negedge RST_N )
	begin
		if (!RST_N)begin
			wrt_Ez_n_addr <= 'd0;
		end
		else begin
			wrt_Ez_n_addr <= wrt_Ez_n_en ? (wrt_Ez_n_addr + 1'b1) : 1'b0;	
		end
	end
//	
 endmodule
