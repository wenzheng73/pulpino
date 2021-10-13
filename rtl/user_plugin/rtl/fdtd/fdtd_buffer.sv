/*-----------------------------------------------//
//Module  : fdtd_buffer.sv
//Version : v1.0.0
//Function: Used to cache electric and magnetic field data
//Author  : Emmet
//Time    : 2021.07
//-----------------------------------------------*/
module fdtd_buffer 
#(  parameter FDTD_DATA_WIDTH    = 32,
    parameter BUFFER_ADDR_WIDTH  = 6
 )
(
	input                                   CLK,
	input                                   RST_N,
	//data_memory -> ram_buffer
	input  logic                            buffer_Hy_start_i,
	input  logic                            buffer_Ez_start_i,
	input  logic                            buffer_src_start_i,
	input  logic                            buffer_Hy_end_i,
	input  logic                            buffer_Ez_end_i,
	input  logic                            buffer_src_end_i,
	//buffer field_value of previous timestep 
	input  logic                            wrtvalid_Hy_old_i,
	input  logic                            wrtvalid_Ez_old_i,
	input  logic  [FDTD_DATA_WIDTH-1:0]     Hy_old_i,	
	input  logic  [FDTD_DATA_WIDTH-1:0]     Ez_old_i,
    //read field_value of previous timestep to participate calculation
	input  logic                            rd_Hy_old_en_i,
	input  logic                            rd_Ez_old_en_i,
	input  logic  [BUFFER_ADDR_WIDTH-1:0]   rd_Hy_old_addr_i,
	input  logic  [BUFFER_ADDR_WIDTH-1:0]   rd_Ez_old_addr_i,
	output logic  [FDTD_DATA_WIDTH-1:0]     Hy_old_o,	
	output logic  [FDTD_DATA_WIDTH-1:0]     Ez_old_o,
	//buffer field_value of current timestep
	input  logic                            wrt_Hy_n_en_i,
	input  logic                            wrt_Ez_n_en_i,
	input  logic  [BUFFER_ADDR_WIDTH-1:0]   wrt_Hy_n_addr_i,	
	input  logic  [BUFFER_ADDR_WIDTH-1:0]   wrt_Ez_n_addr_i,	
	input  logic  [FDTD_DATA_WIDTH-1:0]     Hy_n_i,	
	input  logic  [FDTD_DATA_WIDTH-1:0]     Ez_n_i,	
	//save field_value of current timestep to data_memory
	//ram_buffer -> data_mem
	input  logic                            mem_rd_Hy_en_i,
	input  logic                            mem_rd_Ez_en_i,
	input  logic                            mem_rd_end_i,
	input  logic                            wrtvalid_sgl_i,
	output logic  [FDTD_DATA_WIDTH-1:0]     Hy_n_o,	
	output logic  [FDTD_DATA_WIDTH-1:0]     Ez_n_o	
);
  //
  logic  [BUFFER_ADDR_WIDTH-1:0]  wrtaddr_Hy_old;
  logic  [BUFFER_ADDR_WIDTH-1:0]  wrtaddr_Ez_old;
  logic  [BUFFER_ADDR_WIDTH-1:0]  rdaddr_Hy_n;
  logic  [BUFFER_ADDR_WIDTH-1:0]  rdaddr_Ez_n;
  logic                           en;
  logic                           rd_Hy_en;
  logic                           rd_Ez_en;
  logic                           buffer_Ez_start;
  logic                           buffer_Hy_start;
  logic                           wrt_Hy_old_en;
  logic                           wrt_Ez_old_en;
  //
  //
  enum logic  [2:0] {	
      IDLE,
      BFR_HY,
      BFR_EZ,
      BFR_SRC,
      WAIT0,
      WRT_HY_TO_DM,	
      WRT_EZ_TO_DM	
      } BFR_CS;
  //
  assign  en = 1'b1;
  //
  assign  wrt_Hy_old_en = (BFR_CS == BFR_HY && wrtvalid_Hy_old_i) ? 1'b1:1'b0;
  assign  wrt_Ez_old_en = ((BFR_CS == BFR_EZ || BFR_CS == BFR_SRC )&& wrtvalid_Ez_old_i) ? 1'b1:1'b0;
  //
  assign  rd_Hy_en = (BFR_CS == WRT_HY_TO_DM && wrtvalid_sgl_i) ? 1'b1:1'b0;
  assign  rd_Ez_en = (BFR_CS == WRT_EZ_TO_DM && wrtvalid_sgl_i) ? 1'b1:1'b0;
  //
  //Signal clk delay is done to meet the timing relationship
  always_ff @(posedge CLK or negedge RST_N)
      begin
          if (!RST_N)begin
              buffer_Ez_start <= 1'b0;
              buffer_Hy_start <= 1'b0;
          end
          else begin
              buffer_Ez_start <= buffer_Ez_start_i;
              buffer_Hy_start <= buffer_Hy_start_i;
          end
      end
  //
  always_ff @(posedge CLK or negedge RST_N)
      begin
          if (!RST_N)begin
              wrtaddr_Hy_old <= 'd0;  
              wrtaddr_Ez_old <= 'd0;
              rdaddr_Hy_n <= 'd0;
              rdaddr_Ez_n <= 'd0;
              BFR_CS <= IDLE;
          end
          else begin
          case(BFR_CS)
          IDLE:  	
          begin
              wrtaddr_Hy_old <= 'd0;  
              wrtaddr_Ez_old <= 'd0;
              rdaddr_Hy_n <= 'd0;
              rdaddr_Ez_n <= 'd0;
              if (buffer_Hy_start)
                  BFR_CS <= BFR_HY;
              else if (buffer_Ez_start) 
                  BFR_CS <= BFR_EZ;
              else if (buffer_src_start_i) 
               	  BFR_CS <= BFR_SRC;
              else 
              	  BFR_CS <= IDLE;
          end
  
          BFR_HY:
          begin
              if(buffer_Hy_end_i)begin
                  BFR_CS <= IDLE;
              end
              else begin
                  BFR_CS <= BFR_HY;
                  wrtaddr_Hy_old <= wrtvalid_Hy_old_i ? (wrtaddr_Hy_old + 1'b1) : wrtaddr_Hy_old;
              end
          end
  
          BFR_EZ:
          begin
              if(buffer_Ez_end_i)begin
                  BFR_CS <= WAIT0;
              end
              else begin
                  BFR_CS <= BFR_EZ;
                  wrtaddr_Ez_old <= wrtvalid_Ez_old_i ? (wrtaddr_Ez_old + 1'b1) : wrtaddr_Ez_old;
              end
          end
  		
          BFR_SRC:
          begin
              if(buffer_src_end_i)begin
                  BFR_CS <= WAIT0;
              end
              else begin
                  BFR_CS <= BFR_SRC;
                  wrtaddr_Ez_old <= wrtvalid_Ez_old_i ? (wrtaddr_Ez_old + 1'b1) : wrtaddr_Ez_old;
              end
          end
  
          WAIT0: 
          begin	
              if(mem_rd_Hy_en_i)
                  BFR_CS <= WRT_HY_TO_DM;
              else if(mem_rd_Ez_en_i)
                  BFR_CS <= WRT_EZ_TO_DM;
              else
                  BFR_CS <= WAIT0;
          end
  
          WRT_HY_TO_DM: 
          begin
              if (mem_rd_end_i)begin
                  BFR_CS <= IDLE;
              end
              else 
                  rdaddr_Hy_n <= wrtvalid_sgl_i ? (rdaddr_Hy_n + 1'b1):rdaddr_Hy_n;	
          end
  
         WRT_EZ_TO_DM:
         begin
             if (mem_rd_end_i)begin
                 BFR_CS <= IDLE;
             end
             else
                 rdaddr_Ez_n <= wrtvalid_sgl_i ? (rdaddr_Ez_n + 1'b1):rdaddr_Ez_n;
         end
  		
         default:BFR_CS <= IDLE;
         endcase
         end
      end
  //Hy field_value data of previous timestep
  fdtd_ram  
      #( .FDTD_DATA_WIDTH   ( FDTD_DATA_WIDTH   ),
         .BUFFER_ADDR_WIDTH ( BUFFER_ADDR_WIDTH )
       )
  	   Hy_old_ram_i(
         .CLK    ( CLK             ),	
         .RST_N  ( RST_N           ),	
         .en     ( en              ),	
         .rden   ( rd_Hy_old_en_i  ),	
         .wren   ( wrt_Hy_old_en   ),	
         .addr_a ( wrtaddr_Hy_old  ),	
         .addr_b ( rd_Hy_old_addr_i),	
         .din    ( Hy_old_i        ),	
         .dout   ( Hy_old_o        )	
  	);
  //Ez field_value data of previous timestep
  fdtd_ram   
      #( .FDTD_DATA_WIDTH   ( FDTD_DATA_WIDTH   ),
         .BUFFER_ADDR_WIDTH ( BUFFER_ADDR_WIDTH )
       )
  	   Ez_old_ram_i(
         .CLK    ( CLK             ),	
         .RST_N  ( RST_N           ),	
         .en     ( en              ),	
         .rden   ( rd_Ez_old_en_i  ),	
         .wren   ( wrt_Ez_old_en   ),	
         .addr_a ( wrtaddr_Ez_old  ),	
         .addr_b ( rd_Ez_old_addr_i),	
         .din    ( Ez_old_i        ),	
         .dout   ( Ez_old_o        )	
  	);
  //Hy field_value data of current timestep 
  fdtd_ram  
      #( .FDTD_DATA_WIDTH   ( FDTD_DATA_WIDTH   ),
         .BUFFER_ADDR_WIDTH ( BUFFER_ADDR_WIDTH )
       )
       Hy_new_ram_i(
         .CLK    ( CLK             ),	
         .RST_N  ( RST_N           ),	
         .en     ( en              ),	
         .rden   ( rd_Hy_en        ),	
         .wren   ( wrt_Hy_n_en_i   ),	
         .addr_a ( wrt_Hy_n_addr_i ),	
         .addr_b ( rdaddr_Hy_n     ),	
         .din    ( Hy_n_i          ),	
         .dout   ( Hy_n_o          )	
  	);
  //Ez field_value data of current timestep 
  fdtd_ram  
  	  #( .FDTD_DATA_WIDTH   ( FDTD_DATA_WIDTH   ),
         .BUFFER_ADDR_WIDTH ( BUFFER_ADDR_WIDTH )
       )
  	   Ez_new_ram_i(
         .CLK    ( CLK             ),	
         .RST_N	 ( RST_N           ),	
         .en     ( en              ),	
         .rden 	 ( rd_Ez_en        ),	
         .wren 	 ( wrt_Ez_n_en_i   ),	
         .addr_a ( wrt_Ez_n_addr_i ),	
         .addr_b ( rdaddr_Ez_n     ),	
         .din    ( Ez_n_i          ),	
         .dout   ( Ez_n_o          )	
  	);
  //
  endmodule
  		
  
  
