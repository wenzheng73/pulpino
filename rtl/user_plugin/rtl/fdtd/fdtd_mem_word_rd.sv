`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11


module fdtd_mem_word_rd
#(
    parameter AXI4_ADDR_WIDTH = 32,
    parameter AXI4_DATA_WIDTH = 32,
    parameter AXI4_ID_WIDTH   = 16,
    parameter AXI4_USER_WIDTH = 10,
    parameter AXI4_ARLEN      = 0,
    parameter AXI_STRB_WIDTH  = AXI4_DATA_WIDTH/8
)
(
    input logic     ACLK,
    input logic     ARESETn,

    //AXI read address bus -------------------------------------
    output logic [AXI4_ID_WIDTH-1:0]                ARID_o     ,
    output logic [AXI4_ADDR_WIDTH-1:0]              ARADDR_o   ,
    output logic [ 7:0]                             ARLEN_o    ,
    output logic [ 2:0]                             ARSIZE_o   ,
    output logic [ 1:0]                             ARBURST_o  ,
    output logic                                    ARLOCK_o   ,
    output logic [ 3:0]                             ARCACHE_o  ,
    output logic [ 2:0]                             ARPROT_o   ,
    output logic [ 3:0]                             ARREGION_o ,
    output logic [ AXI4_USER_WIDTH-1:0]             ARUSER_o   ,
    output logic [ 3:0]                             ARQOS_o    ,
    output logic                                    ARVALID_o  ,
    input  logic                                    ARREADY_i  ,
    // ---------------------------------------------------------

    //AXI read data bus ----------------------------------------
    input  logic [AXI4_ID_WIDTH-1:0]                RID_i      ,
    input  logic [AXI4_DATA_WIDTH-1:0]              RDATA_i    ,
    input  logic [ 1:0]                             RRESP_i    ,
    input  logic                                    RLAST_i    ,
    input  logic [AXI4_USER_WIDTH-1:0]              RUSER_i    ,
    input  logic                                    RVALID_i   ,
    output logic                                    RREADY_o   ,
    // ---------------------------------------------------------

    // When x_req_i becomes high, 
    // x_req_i must keep high,
    // and x_addr_i / x_data_i should not change,
    // until x_gnt_o becomes high.
    input  logic                                    rd_req_i       ,
    input  logic [AXI4_ADDR_WIDTH-2-1:0]            rd_word_addr_i ,
    output logic [AXI4_DATA_WIDTH-1:0]              rd_data_o      ,
    output logic                                    rd_gnt_o
);

logic [AXI4_ADDR_WIDTH - 1: 0] s_r_addr;
logic [7:0]		       read_burst_cnt;
logic			       rd_req;
// Extend word addr to byte addr
assign s_r_addr =  {rd_word_addr_i,2'h0};
////////////////////
// AXI Read Logic //
////////////////////
assign ARID_o     = 'b0;
assign ARADDR_o   = s_r_addr;
assign ARLEN_o    = AXI4_ARLEN;
assign ARSIZE_o   = 'd2;
assign ARBURST_o  = 2'b01;
assign ARLOCK_o   = 'b0;
assign ARCACHE_o  = 'b0;
assign ARPROT_o   = 'b0;
assign ARREGION_o = 'b0;
assign ARUSER_o   = 'b0;
assign ARQOS_o    = 'b0;

assign RREADY_o   = 'b1;
assign rd_data_o  = RDATA_i;
assign rd_gnt_o   = rd_req & RVALID_i & RLAST_i;

enum logic [1:0] {  RS_WAIT_REQ,
                    RS_WAIT_ARREADY,
                    RS_WAIT_RLAST
                 } r_RS, s_RS_n;

always_ff @ (posedge ACLK, negedge ARESETn)
begin
    if (~ARESETn)
        r_RS <= RS_WAIT_REQ;
    else
        r_RS <= s_RS_n;
end
//
always_ff @(posedge ACLK, negedge ARESETn)
begin
    if (~ARESETn)
        rd_req <= 'd0;
    else
	rd_req <= rd_req_i;
end
// FIXME: Only
//            RS_WAIT_REQ -> RS_WAIT_RLAST -> RS_WAIT_REQ
//        state transfers have been accessed.
//        Should use BFM to test the whole FSM.
//
/*always_ff @(posedge ACLK or negedge ARESETn)
	begin
		if (!ARESETn)
			read_burst_cnt <= 'd0;
		else if(read_burst_cnt == AXI4_ARLEN - 1'b1)
			read_burst_cnt <= 'd0;
		else
			read_burst_cnt <=( ARREADY_i&&ARVALID_o )? (read_burst_cnt + 1'b1) : read_burst_cnt;
	end*/	
//
always_comb
begin
    ARVALID_o = 1'b0;

    case (r_RS)
        RS_WAIT_REQ:
        begin
            if (~rd_req)
                s_RS_n = RS_WAIT_REQ;
            else
            begin
                ARVALID_o = 1'b1;

		if (~ARREADY_i)
			s_RS_n = RS_WAIT_ARREADY;
		else 
			s_RS_n = RS_WAIT_RLAST;

            end
        end

        RS_WAIT_ARREADY:
        begin
            ARVALID_o = 1'b1;

		if (~ARREADY_i)
			s_RS_n = RS_WAIT_ARREADY;
		else 
		        s_RS_n = RS_WAIT_RLAST;	
        end 

        RS_WAIT_RLAST:
        begin
            if (~(RVALID_i & RLAST_i))
                s_RS_n = RS_WAIT_RLAST;
            else
                s_RS_n = RS_WAIT_REQ;
        end

        default:
            s_RS_n = RS_WAIT_REQ;

    endcase
end

endmodule
