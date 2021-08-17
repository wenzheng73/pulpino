/*-----------------------------------------------//
//Module_name:fdtd_ram
//Version:
//Function_Description:
//Author: Emmet
//Time:
//-----------------------------------------------*/

module fdtd_ram 
#(	parameter 	FDTD_DATA_WIDTH	 = 32,
	parameter	BUFFER_ADDR_WIDTH= 6
)
(
	input					CLK,		
	input					RST_N,
	//
	input	logic				en,
	input	logic				rden,
	input	logic				wren,
	input	logic [BUFFER_ADDR_WIDTH-1:0]   addr_a,
	input	logic [BUFFER_ADDR_WIDTH-1:0]   addr_b,
	input	logic [FDTD_DATA_WIDTH-1:0]	din,
	//
	output  logic [FDTD_DATA_WIDTH-1:0]	dout
);
//
localparam RAM_DEPTH = 2**BUFFER_ADDR_WIDTH;
logic	[FDTD_DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
//
integer i;
//write data
always_ff @(posedge CLK or negedge RST_N)
	begin
		if (!RST_N)begin
		for(i=0;i<RAM_DEPTH;i=i+1)
			ram[i] <= 'd0;
		end
		else if (en && wren)
			ram[addr_a] <= din;
	end
//read data
assign dout = rden ? ram[addr_b] : 'd0;
//
endmodule

