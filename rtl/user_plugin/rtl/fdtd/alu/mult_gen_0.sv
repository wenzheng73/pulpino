module mult_gen_0
#(parameter WIDTH = 32)
(
	input 					CLK,
	input 					CE,
	//
	input 	logic signed [WIDTH-1:0]	A,
	input 	logic signed [WIDTH-1:0]	B,
	//
	output  logic signed [2*WIDTH-1:0]	P
);
//
reg signed [2*WIDTH-1:0] result;
//
always_ff @(posedge CLK)begin
	if (CE == 1'b0)
		result <= 'd0;
	else if (CE == 1'b1)
		result <= A*B;
	else
		result <= 'd0;
end
//
assign P = result;
//
endmodule

