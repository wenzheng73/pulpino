`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

module fdtd_mem_word_wt
#(
    parameter AXI4_ADDR_WIDTH = 32,
    parameter AXI4_DATA_WIDTH = 32,
    parameter AXI4_ID_WIDTH   = 16,
    parameter AXI4_USER_WIDTH = 10,
    parameter AXI_STRB_WIDTH  = AXI4_DATA_WIDTH/8
)
(
    input logic     ACLK,
    input logic     ARESETn,

    //AXI write address bus ------------------------------------
    output logic [AXI4_ID_WIDTH-1:0]                AWID_o     ,
    output logic [AXI4_ADDR_WIDTH-1:0]              AWADDR_o   ,
    output logic [ 7:0]                             AWLEN_o    ,
    output logic [ 2:0]                             AWSIZE_o   ,
    output logic [ 1:0]                             AWBURST_o  ,
    output logic                                    AWLOCK_o   ,
    output logic [ 3:0]                             AWCACHE_o  ,
    output logic [ 2:0]                             AWPROT_o   ,
    output logic [ 3:0]                             AWREGION_o ,
    output logic [ AXI4_USER_WIDTH-1:0]             AWUSER_o   ,
    output logic [ 3:0]                             AWQOS_o    ,
    output logic                                    AWVALID_o  ,
    input  logic                                    AWREADY_i  ,
    // ---------------------------------------------------------

    //AXI write data bus ---------------------------------------
    output logic [AXI4_DATA_WIDTH-1:0]              WDATA_o    ,
    output logic [AXI_STRB_WIDTH-1:0]               WSTRB_o    ,
    output logic                                    WLAST_o    ,
    output logic [AXI4_USER_WIDTH-1:0]              WUSER_o    ,
    output logic                                    WVALID_o   ,
    input  logic                                    WREADY_i   ,
    // ---------------------------------------------------------

    //AXI write response bus -----------------------------------
    input  logic   [AXI4_ID_WIDTH-1:0]              BID_i      ,
    input  logic   [ 1:0]                           BRESP_i    ,
    input  logic                                    BVALID_i   ,
    input  logic   [AXI4_USER_WIDTH-1:0]            BUSER_i    ,
    output logic                                    BREADY_o   ,
    // ---------------------------------------------------------

    // When x_req_i becomes high, 
    // x_req_i must keep high,
    // and x_addr_i / x_data_i should not change,
    // until x_gnt_o becomes high.
    input  logic                                    wt_req_i       ,
    input  logic [AXI4_ADDR_WIDTH-2-1:0]            wt_word_addr_i ,
    input  logic [AXI4_DATA_WIDTH-1:0]              wt_data_i      ,
    output logic                                    wt_gnt_o
);

logic [AXI4_ADDR_WIDTH - 1: 0] s_w_addr;
logic			       wt_req_r;
assign s_w_addr = {wt_word_addr_i, 2'h0};  // Extend word addr to byte addr

assign AWID_o     = 'b0;
assign AWADDR_o   = s_w_addr;
assign AWLEN_o    = 'd0;
assign AWSIZE_o   = 'd2;
assign AWBURST_o  = 2'b01;
assign AWLOCK_o   = 'b0;
assign AWCACHE_o  = 'b0;
assign AWPROT_o   = 'b0;
assign AWREGION_o = 'b0;
assign AWUSER_o   = 'b0;
assign AWQOS_o    = 'b0;

assign WDATA_o    = wt_data_i;
assign WSTRB_o    = {AXI_STRB_WIDTH{1'b1}};
assign WUSER_o    = 'b0;

assign BREADY_o   = 1'b1;


// FIXME: USE PROPER STATE WIDTH
enum logic [1:0] {  WS_WAIT_REQ,
                    WS_WAIT_AWREADY,
                    WS_WRITE,
                    WS_WAIT_BVALID
                 } r_WS, s_WS_n;

always_ff @ (posedge ACLK, negedge ARESETn)
begin
    if (~ARESETn)
        r_WS <= WS_WAIT_REQ;
    else
        r_WS <= s_WS_n;
end
//
always_ff @(posedge ACLK, negedge ARESETn)
begin
    if (~ARESETn)
        wt_req_r <= 'd0;
    else
	wt_req_r <= wt_req_i;
end

// FIXME: Only
//            WS_WAIT_REQ -> WS_WRITE -> WS_WAIT_BVALID -> WS_WAIT_REQ
//        state transfers have been accessed.
//        Should use BFM to test the whole FSM.
always_comb
begin
    AWVALID_o = 1'b0;
    WLAST_o   = 1'b0;
    WVALID_o  = 1'b0;

    wt_gnt_o  = 1'b0;

    case (r_WS)
        WS_WAIT_REQ:
        begin
            if (~wt_req_r)
                s_WS_n = WS_WAIT_REQ;
            else
            begin
                AWVALID_o = 1'b1;

                if (~AWREADY_i)
                    s_WS_n = WS_WAIT_AWREADY;
                else
                    s_WS_n = WS_WRITE;
            end
        end

        WS_WAIT_AWREADY:
        begin
            AWVALID_o = 1'b1;

            if (~AWREADY_i)
                s_WS_n = WS_WAIT_AWREADY;
            else
                s_WS_n = WS_WRITE;
        end

        WS_WRITE:
        begin
            WVALID_o = 1'b1;
            WLAST_o  = 1'b1;

            if (~WREADY_i)
                s_WS_n = WS_WRITE;
            else
                s_WS_n = WS_WAIT_BVALID;
        end

        WS_WAIT_BVALID:
        begin
            if (~BVALID_i)
                s_WS_n = WS_WAIT_BVALID; 
            else
            begin
                wt_gnt_o = 1'b1;
                s_WS_n   = WS_WAIT_REQ;
            end
        end

        default:
        begin
            s_WS_n = WS_WAIT_REQ;
        end
    endcase
end

endmodule
