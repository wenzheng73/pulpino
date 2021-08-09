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
reg [FDTD_DATA_WIDTH-1:0] temp_r0;
reg [FDTD_DATA_WIDTH-1:0] temp_r1;
//
always @(posedge CLK or negedge RST_N)begin
	if (!RST_N)begin
		temp_r0 <= 'd0;
		temp_r1 <= 'd0;
	else begin
		temp_r0 <= data_i;
		temp_r1 <= temp_r0;
	end
//
assign data_o = temp_r1;
//
endmodule
	


