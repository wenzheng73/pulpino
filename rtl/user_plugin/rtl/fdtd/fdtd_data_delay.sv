module fdtd_data_delay
#(
   FDTD_DATA_WIDTH = 32,
   DELAY_STAGE     = 2
)
(
	input  					CLK,
	input 					RST_N,
	input  logic [FDTD_DATA_WIDTH-1:0]	data_i,
	output logic [FDTD_DATA_WIDTH-1:0]	data_o
);
//
/*logic [FDTD_DATA_WIDTH-1:0] temp_r0;
logic [FDTD_DATA_WIDTH-1:0] temp_r1;
logic [2:0]   		    buffer_stage;
//
assign buffer_stage = DELAY_STAGE;
//
always @(posedge CLK or negedge RST_N)begin
	if (!RST_N)begin
		temp_r0 <= 'd0;
		temp_r1 <= 'd0;
	end
	else case (buffer_stage)
	  'd1:  begin
		  temp_r1 <= data_i;
		end 
	  'd2:  begin
		  temp_r0 <= data_i;
		  temp_r1 <= temp_r0;
	        end
	  default: temp_r1 <= 'd0;
	endcase
end
//
assign data_o = temp_r1;*/
//
logic [DELAY_STAGE-1:0] delay_stage;
logic [FDTD_DATA_WIDTH-1:0] delay_ram [DELAY_STAGE-1:0];
//
assign delay_stage = DELAY_STAGE;
//
integer i;
//
always_ff @(posedge CLK ,negedge RST_N)begin
	if(!RST_N)begin
            for (i=0;i<DELAY_STAGE;i=i+1)begin
		    delay_ram[i] <= 'd0;
	
	    end
	end
	else if (delay_stage <= 1)begin
            delay_ram[delay_stage - 1] <= data_i;
        end
	else begin  
            for (i=0; i<DELAY_STAGE; i=i+1)begin
                delay_ram[i] <= data_i;
		delay_ram[i+1]<= delay_ram[i];
	    end
	end
    end
//
assign data_o = delay_ram[DELAY_STAGE-1];
//
endmodule
	


