module fdtd_data_delay
#(
   DATA_WIDTH      = 32,
   DELAY_STAGE     = 2
)
(
	input  					CLK,
	input 					RST_N,
	input  logic [DATA_WIDTH-1:0]	        data_i,
	output logic [DATA_WIDTH-1:0]	        data_o
);
//
logic [DELAY_STAGE-1:0]delay_stage;
logic [DATA_WIDTH-1:0] data_r;
//
assign delay_stage = DELAY_STAGE;
//
always_ff @(posedge CLK, negedge RST_N)begin
	if(!RST_N)
           data_o <= 'd0;
        else case(delay_stage)
	1: data_o <= data_i;
        2: begin
              data_r <= data_i;
	      data_o <= data_r;
	   end
	default:data_o <= 'd0;
        endcase
    end
//
endmodule
	


