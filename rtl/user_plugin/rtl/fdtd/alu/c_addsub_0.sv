module c_addsub_0
#(
    parameter WIDTH = 32
	)
(
	input 				CLK,
	//
	input 				ADD,
	input 				CE,
	input  logic signed [WIDTH-1:0]	A,
	input  logic signed [WIDTH-1:0]	B,
	//
	output logic signed [WIDTH-1:0]	S
);
//
reg signed [WIDTH-1:0] s_reg;
//
always_ff @(posedge CLK)begin
	if (CE == 1'b0)
		s_reg <= 'd0;
	else begin
		if (ADD == 1'b0)
			s_reg <= A-B;
		else if (ADD == 1'b1)
			s_reg <= A+B;
		else 
			s_reg <= 'd0;
	end
end
//
assign S = s_reg;
//
endmodule
