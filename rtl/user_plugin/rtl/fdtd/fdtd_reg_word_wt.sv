`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

// Convert AXI Slave bus to simpler read/write signals
module fdtd_reg_word_wt
#(
    parameter AXI4_ADDR_WIDTH = 32,
    parameter AXI4_DATA_WIDTH = 32,
    parameter AXI4_ID_WIDTH   = 16,
    parameter AXI4_USER_WIDTH = 10,
    parameter AXI_STRB_WIDTH  = AXI4_DATA_WIDTH/8,

    parameter WORD_ADDR_WIDTH = 4
)
(
    input logic                                     ACLK,
    input logic                                     ARESETn,

    //AXI write address bus ------------------------------------
    input  logic [AXI4_ID_WIDTH-1:0]                AWID_i     ,
    input  logic [AXI4_ADDR_WIDTH-1:0]              AWADDR_i   ,
    input  logic [ 7:0]                             AWLEN_i    ,
    input  logic [ 2:0]                             AWSIZE_i   ,
    input  logic [ 1:0]                             AWBURST_i  ,
    input  logic                                    AWLOCK_i   ,
    input  logic [ 3:0]                             AWCACHE_i  ,
    input  logic [ 2:0]                             AWPROT_i   ,
    input  logic [ 3:0]                             AWREGION_i ,
    input  logic [ AXI4_USER_WIDTH-1:0]             AWUSER_i   ,
    input  logic [ 3:0]                             AWQOS_i    ,
    input  logic                                    AWVALID_i  ,
    output logic                                    AWREADY_o  ,
    // ---------------------------------------------------------

    //AXI write data bus ---------------------------------------
    input  logic [AXI4_DATA_WIDTH-1:0]              WDATA_i    ,
    input  logic [AXI_STRB_WIDTH-1:0]               WSTRB_i    ,
    input  logic                                    WLAST_i    ,
    input  logic [AXI4_USER_WIDTH-1:0]              WUSER_i    ,
    input  logic                                    WVALID_i   ,
    output logic                                    WREADY_o   ,
    // ---------------------------------------------------------

    //AXI write response bus -----------------------------------
    output logic   [AXI4_ID_WIDTH-1:0]              BID_o      ,
    output logic   [ 1:0]                           BRESP_o    ,
    output logic                                    BVALID_o   ,
    output logic   [AXI4_USER_WIDTH-1:0]            BUSER_o    ,
    input  logic                                    BREADY_i   ,
    // ---------------------------------------------------------

    // When valid_o is true,
    // word_addr_o, data_o, strb_o are valid,
    // and data_o should be written to a reg.
    output logic                                    valid_o     ,
    output logic [WORD_ADDR_WIDTH-1:0]              word_addr_o ,
    output logic [AXI4_DATA_WIDTH-1:0]              data_o      ,
    output logic [AXI_STRB_WIDTH-1:0]               strb_o
);

    /////////////////////
    // AXI Write Logic //
    /////////////////////

    // According to the spec: ARM IHI 0022E
    // aw channel and w channel are independent.
    // Thus:
    // 1. aw channel may be valid before w channel.
    // 2. w channel may be valid before aw channel.
    // 3. aw channel and w channel may be valid together.
    //
    // To simplify write logic, and take care of burst transaction,
    // Only the first beat of a write transaction is written to a reg.
    //
    // To simplify write logic, and avoid storing w channel information with
    // intermediate ffs. Store aw information first, and a write can access user
    // regs directly.

    logic                           s_aw_store;
    logic [AXI4_ID_WIDTH-1 : 0]     r_awid;
    logic [WORD_ADDR_WIDTH - 1 : 0] s_aw_word_addr;
    logic [WORD_ADDR_WIDTH - 1 : 0] r_aw_word_addr;

    // Write data to reg from stored wdata and awaddr.
    logic                           s_write;

    assign s_aw_word_addr = AWADDR_i[WORD_ADDR_WIDTH + 2 - 1 : 2];

    assign BID_o     = r_awid;
    assign BRESP_o   = `OKAY;
    assign BUSER_o   = 'h0;

    assign valid_o     = s_write;
    assign word_addr_o = r_aw_word_addr;
    assign data_o      = WDATA_i;
    assign strb_o      = WSTRB_i;

    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
        begin
            r_awid         <= 'b0;
            r_aw_word_addr <= 'b0;
        end
        else if (s_aw_store)
             begin
                r_awid         <= AWID_i;
                r_aw_word_addr <= s_aw_word_addr;
             end
    end

    enum logic [1:0] { WAIT_AWVALID,  
                       WAIT_WVALID,
                       WAIT_WLAST,
                       WAIT_BREADY 
                     } r_WS, s_WS_n;
    

    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_WS <= WAIT_AWVALID;
        else
            r_WS <= s_WS_n;
    end

    // FIXME: It seems PULPino only support 1-beat transaction.
    //        Only
    //            WAIT_AWVALID -> WAIT_WVALID -> WAIT_BREADY -> WAIT_AWVALID
    //        state transfers have been accessed.
    //        Should use BFM to test the whole FSM.
    always_comb
    begin
        AWREADY_o = 1'b0;
        WREADY_o  = 1'b0;
        BVALID_o  = 1'b0;

        s_aw_store = 1'b0;
        s_write    = 1'b0;

        case (r_WS)
            WAIT_AWVALID:
            begin
                AWREADY_o = 1'b1;

                if (~AWVALID_i)
                    s_WS_n    = WAIT_AWVALID;
                else
                begin
                   s_aw_store = 1'b1;

                   s_WS_n     = WAIT_WVALID;
                end
            end

            WAIT_WVALID:
            begin
                WREADY_o   = 1'b1;

                if (~WVALID_i)
                    s_WS_n = WAIT_WVALID;
                else
                begin
                    // WVALID_i
                    s_write = 1'b1;

                    if (WLAST_i)
                        // WVALID_i && WLAST_i
                        s_WS_n = WAIT_BREADY;
                    else
                        // WVALID_i && ~WLAST_i
                        s_WS_n = WAIT_WLAST;
                end
            end

            WAIT_WLAST:
            begin
                WREADY_o   = 1'b1;

                if (~WLAST_i)
                    s_WS_n = WAIT_WLAST;
                else
                    s_WS_n = WAIT_BREADY;
            end
           
            WAIT_BREADY:
            begin
                BVALID_o   = 1'b1;

                if (BREADY_i)
                    s_WS_n = WAIT_AWVALID;
                else
                    s_WS_n = WAIT_BREADY;
            end

            default:
            begin
                s_WS_n = WAIT_AWVALID;
            end
        endcase
    end

endmodule
