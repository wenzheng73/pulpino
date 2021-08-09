`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

// Convert AXI Slave bus to simpler read/write signals
module fdtd_reg_word_rd
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

    //AXI read address bus -------------------------------------
    input  logic [AXI4_ID_WIDTH-1:0]                ARID_i     ,
    input  logic [AXI4_ADDR_WIDTH-1:0]              ARADDR_i   ,
    input  logic [ 7:0]                             ARLEN_i    ,
    input  logic [ 2:0]                             ARSIZE_i   ,
    input  logic [ 1:0]                             ARBURST_i  ,
    input  logic                                    ARLOCK_i   ,
    input  logic [ 3:0]                             ARCACHE_i  ,
    input  logic [ 2:0]                             ARPROT_i   ,
    input  logic [ 3:0]                             ARREGION_i ,
    input  logic [ AXI4_USER_WIDTH-1:0]             ARUSER_i   ,
    input  logic [ 3:0]                             ARQOS_i    ,
    input  logic                                    ARVALID_i  ,
    output logic                                    ARREADY_o  ,
    // ---------------------------------------------------------

    //AXI read data bus ----------------------------------------
    output logic [AXI4_ID_WIDTH-1:0]                RID_o      ,
    output logic [AXI4_DATA_WIDTH-1:0]              RDATA_o    ,
    output logic [ 1:0]                             RRESP_o    ,
    output logic                                    RLAST_o    ,
    output logic [AXI4_USER_WIDTH-1:0]              RUSER_o    ,
    output logic                                    RVALID_o   ,
    input  logic                                    RREADY_i   ,
    // ---------------------------------------------------------

    // When avalid_o is true,
    // word_addr_o is valid, and data_i will be sampled by AXI bus.
    output logic                                    avalid_o    ,
    output logic [WORD_ADDR_WIDTH-1:0]              word_addr_o ,
    input  logic [AXI4_DATA_WIDTH-1:0]              data_i
);

    // Only support 1 ongoing transaction.
    // No outstanding reading supported.
    // When a transaction contains multiple beats, 
    // all beats contain the same data (the data from ARADDR)

    // Control signals
    // Store AR* values.
    logic                           s_ar_store;
    // Decrease lathed arlen, when true
    logic                           s_arlen_dec;

    logic [WORD_ADDR_WIDTH - 1 : 0] s_araddr;
    logic [7:0]                     r_arlen;

    logic [AXI4_ID_WIDTH-1 : 0]     r_rid;
    logic [AXI4_DATA_WIDTH - 1: 0]  r_rdata;


    assign s_araddr = ARADDR_i[WORD_ADDR_WIDTH + 2 - 1 : 2];

    assign RID_o    = r_rid;
    assign RDATA_o  = r_rdata;

    assign RRESP_o  = `OKAY;
    assign RUSER_o  = 'b0;

    assign avalid_o    = s_ar_store;
    assign word_addr_o = s_araddr;


    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_arlen <= 'b0;
        else if (s_ar_store)
            r_arlen <= ARLEN_i;
        else if (s_arlen_dec)
            r_arlen <= r_arlen - 1;
    end

    //
    // r logic
    //
    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
        begin
            r_rid   <= 'b0;
            r_rdata <= 'b0;
        end
        else if (s_ar_store)
             begin
                 r_rid   <= ARID_i;
                 r_rdata <= data_i;
             end
    end

    enum logic [0:0] { WAIT_ARVALID,
                       SEND_DATA
                     } r_RS, s_RS_n;

    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_RS <= WAIT_ARVALID;
        else
            r_RS <= s_RS_n;
    end


    // FIXME: It seems PULPino only support 1-beat transaction.
    //        Only
    //            WAIT_ARVALID -> SEND_DATA -> WAIT_ARVALID
    //        state transfers have been accessed.
    //        Should use BFM to test the whole FSM.
    always_comb
    begin
        ARREADY_o   = 1'b0;
        RVALID_o    = 1'b0;
        RLAST_o     = 1'b0;

        s_ar_store  = 1'b0;
        s_arlen_dec = 1'b0;

        case (r_RS)
            WAIT_ARVALID:
            begin
                ARREADY_o   = 1'b1;

                if (~ARVALID_i)
                begin
                    s_RS_n      = WAIT_ARVALID;
                end
                else
                begin
                    s_ar_store  = 1'b1;

                    s_RS_n      = SEND_DATA;
                end
            end

            SEND_DATA:
            begin
                RVALID_o    = 1'b1;
                RLAST_o     = (r_arlen == 'b0);

                s_arlen_dec = (r_arlen != 'b0) && RREADY_i;

                if (~RREADY_i)
                    s_RS_n = SEND_DATA;
                else 
                    if (r_arlen == 'b0)
                        s_RS_n = WAIT_ARVALID;
                    else
                        s_RS_n = SEND_DATA;
            end

            default:
            begin
                s_RS_n = WAIT_ARVALID;
            end
        endcase
    end

endmodule
