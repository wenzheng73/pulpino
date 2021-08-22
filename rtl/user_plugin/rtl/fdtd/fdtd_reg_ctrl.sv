`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

`define WORD_ADDR_WIDTH 8

`define REG_CEZE              8'h00   // BASEADDR + 0x00
`define REG_CEZHY             8'h01   // BASEADDR + 0x04
`define REG_CEZJ              8'h02   // BASEADDR + 0x08
`define REG_CHYH              8'h03   // BASEADDR + 0x0C
`define REG_CHYEZ             8'h04   // BASEADDR + 0x10
`define REG_CHYM              8'h05   // BASEADDR + 0x14
`define REG_COE0              8'h06   // BASEADDR + 0x18
`define REG_SOURCE            8'h07   // BASEADDR + 0x1C

`define REG_SIZE              8'h08   // BASEADDR + 0x24
`define REG_CTRL              8'h09   // BASEADDR + 0x28
`define REG_CMD               8'h0A   // BASEADDR + 0x2C
`define REG_STATUS            8'h0B   // BASEADDR + 0x30
`define REG_START_CALC_SGL    8'h0C   // BASEADDR + 0x34

`define REG_HY_ADDR           8'h0D   // BASEADDR + 0x38
`define REG_EZ_ADDR           8'h0E   // BASEADDR + 0x3C
`define REG_CALC_HY_SGL       8'h0F   // BASEADDR + 0x48
`define REG_CALC_EZ_SGL       8'h10   // BASEADDR + 0x4C
`define REG_CALC_SRC_SGL      8'h11   // BASEADDR + 0x50


`define CTRL_INT_EN_BIT        'd0

`define REG_CMD_WIDTH            2
`define CMD_CLR_INT_BIT        'd0
`define CMD_TRIGGER_BIT        'd1

`define FDTD_CALC_SIGNAL_BIT   'd1

`define STATUS_BUSY_BIT        'd0
`define STATUS_INT_PENDING_BIT 'd1


module fdtd_reg_ctrl
#(
    parameter REG_SIZE_WIDTH = 16
)
(
    input logic                                     ACLK,
    input logic                                     ARESETn,

    AXI_BUS.Slave                                   slv,

    //user defined signals -------------------------------
    //fdtd coefficients
    output logic signed [slv.AXI_DATA_WIDTH - 1:0]  ceze ,         
    output logic signed [slv.AXI_DATA_WIDTH - 1:0]  cezhy,        
    output logic signed [slv.AXI_DATA_WIDTH - 1:0]  cezj ,
    output logic signed [slv.AXI_DATA_WIDTH - 1:0]  chyh ,
    output logic signed [slv.AXI_DATA_WIDTH - 1:0]  chyez,
    output logic signed [slv.AXI_DATA_WIDTH - 1:0]  coe0 ,
    output logic signed [slv.AXI_DATA_WIDTH - 1:0]  Jz   ,

    //start fdtd calc signal
    output logic                                    fdtd_start_signal_o,

    output logic                                    calc_Hy_start_en_o,
    output logic                                    calc_Ez_start_en_o,
    output logic                                    calc_src_start_en_o,
    input  logic                                    calc_Hy_end_flg_i,
    input  logic                                    calc_Ez_end_flg_i,
    input  logic                                    calc_src_end_flg_i,
    //
    //field value addr
    output logic [slv.AXI_ADDR_WIDTH - 1:0]         Hy_addr_o,
    output logic [slv.AXI_ADDR_WIDTH - 1:0]         Ez_addr_o,

    //user logic
    //
    output logic [REG_SIZE_WIDTH - 1:0]             size_o       ,        // process byte number
    output logic                                    ctrl_int_en_o,        // interrupt enable output
    output logic                                    cmd_clr_int_pulse_o,  // clear int signal (pulse)
    output logic                                    cmd_trigger_pulse_o,  // trigger signal (pulse)

    input  logic                                    status_busy_i,        // status busy
    input  logic                                    status_int_pending_i  // status int pending

);

    logic                           s_write;
    logic [`WORD_ADDR_WIDTH - 1:0]  s_w_word_addr; 
    logic [slv.AXI_DATA_WIDTH-1:0]  s_wdata;
    logic [slv.AXI_STRB_WIDTH-1:0]  s_wstrb;

    logic [`WORD_ADDR_WIDTH - 1:0]  s_r_word_addr; 
    logic [slv.AXI_DATA_WIDTH-1:0]  s_rdata;			    
    //-------------------------------------------------//
    fdtd_reg_word_rd
    #(
        .AXI4_ADDR_WIDTH ( slv.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( slv.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( slv.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( slv.AXI_USER_WIDTH ),

        .WORD_ADDR_WIDTH ( `WORD_ADDR_WIDTH   )
    )
    reg_word_rd_i
    (
        .ACLK       ( ACLK          ),
        .ARESETn    ( ARESETn       ),

        .ARID_i     ( slv.ar_id     ),
        .ARADDR_i   ( slv.ar_addr   ),
        .ARLEN_i    ( slv.ar_len    ),
        .ARSIZE_i   ( slv.ar_size   ),
        .ARBURST_i  ( slv.ar_burst  ),
        .ARLOCK_i   ( slv.ar_lock   ),
        .ARCACHE_i  ( slv.ar_cache  ),
        .ARPROT_i   ( slv.ar_prot   ),
        .ARREGION_i ( slv.ar_region ),
        .ARUSER_i   ( slv.ar_user   ),
        .ARQOS_i    ( slv.ar_qos    ),
        .ARVALID_i  ( slv.ar_valid  ),
        .ARREADY_o  ( slv.ar_ready  ),
                                   
        .RID_o      ( slv.r_id      ),
        .RDATA_o    ( slv.r_data    ),
        .RRESP_o    ( slv.r_resp    ),
        .RLAST_o    ( slv.r_last    ),
        .RUSER_o    ( slv.r_user    ),
        .RVALID_o   ( slv.r_valid   ),
        .RREADY_i   ( slv.r_ready   ),

        .avalid_o    (),
        .word_addr_o ( s_r_word_addr ),
        .data_i      ( s_rdata       )
    );

    fdtd_reg_word_wt
    #(
        .AXI4_ADDR_WIDTH ( slv.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( slv.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( slv.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( slv.AXI_USER_WIDTH ),
        .WORD_ADDR_WIDTH ( `WORD_ADDR_WIDTH   )
    )
    reg_word_wt_i
    (
        .ACLK       ( ACLK          ),
        .ARESETn    ( ARESETn       ),

        .AWID_i     ( slv.aw_id     ),
        .AWADDR_i   ( slv.aw_addr   ),
        .AWLEN_i    ( slv.aw_len    ),
        .AWSIZE_i   ( slv.aw_size   ),
        .AWBURST_i  ( slv.aw_burst  ),
        .AWLOCK_i   ( slv.aw_lock   ),
        .AWCACHE_i  ( slv.aw_cache  ),
        .AWPROT_i   ( slv.aw_prot   ),
        .AWREGION_i ( slv.aw_region ),
        .AWUSER_i   ( slv.aw_user   ),
        .AWQOS_i    ( slv.aw_qos    ),
        .AWVALID_i  ( slv.aw_valid  ),
        .AWREADY_o  ( slv.aw_ready  ),
                                   
        .WDATA_i    ( slv.w_data    ),
        .WSTRB_i    ( slv.w_strb    ),
        .WLAST_i    ( slv.w_last    ),
        .WUSER_i    ( slv.w_user    ),
        .WVALID_i   ( slv.w_valid   ),
        .WREADY_o   ( slv.w_ready   ),
                                  
        .BID_o      ( slv.b_id      ),
        .BRESP_o    ( slv.b_resp    ),
        .BVALID_o   ( slv.b_valid   ),
        .BUSER_o    ( slv.b_user    ),
        .BREADY_i   ( slv.b_ready   ),

        .valid_o     ( s_write       ),
        .word_addr_o ( s_w_word_addr ),
        .data_o      ( s_wdata       ),
        .strb_o      ( s_wstrb       )
    );

    ////////////////
    // User Logic //
    ////////////////
    // User reg write
    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
        begin
            ceze    <= 'b0;
            cezhy   <= 'b0;   
            cezj    <= 'b0;
            chyh    <= 'b0;
            chyez   <= 'b0;
            coe0    <= 'b0;
            Jz      <= 'b0;

            size_o        <= 'b0;
            ctrl_int_en_o <= 'b0;

            fdtd_start_signal_o <= 'b0;
            calc_Hy_start_en_o <= 'b0;
            calc_Ez_start_en_o <= 'b0;
            calc_src_start_en_o <= 'b0;
            
            Hy_addr_o <= 'b0; 
            Ez_addr_o <= 'b0; 

        end
        else if (s_write)
             begin
                 case (s_w_word_addr)
                     `REG_CEZE:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 ceze[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_CEZHY:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 cezhy[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];	  
                     `REG_CEZJ:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 cezj[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_CHYH:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 chyh[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_CHYEZ:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 chyez[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_COE0:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 coe0[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_SOURCE:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 Jz[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_START_CALC_SGL:
                         if (s_wstrb[`FDTD_CALC_SIGNAL_BIT / 8])
                             fdtd_start_signal_o <= s_wdata[`FDTD_CALC_SIGNAL_BIT];
                     `REG_SIZE:
                         for (int i = 0; i < $size(size_o); i++)
                             if (s_wstrb[i / 8])
                                 size_o[i] <= s_wdata[i];
                     `REG_CTRL:
                         if (s_wstrb[`CTRL_INT_EN_BIT / 8])
                             ctrl_int_en_o <= s_wdata[`CTRL_INT_EN_BIT];
                     `REG_HY_ADDR:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 Hy_addr_o[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_EZ_ADDR:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 Ez_addr_o[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_CALC_HY_SGL:
                         if (s_wstrb[`FDTD_CALC_SIGNAL_BIT / 8])
                             calc_Hy_start_en_o <= s_wdata[`FDTD_CALC_SIGNAL_BIT];
                     `REG_CALC_EZ_SGL:
                         if (s_wstrb[`FDTD_CALC_SIGNAL_BIT / 8])
                             calc_Ez_start_en_o <= s_wdata[`FDTD_CALC_SIGNAL_BIT];
                     `REG_CALC_SRC_SGL:
                         if (s_wstrb[`FDTD_CALC_SIGNAL_BIT / 8])
                             calc_src_start_en_o <= s_wdata[`FDTD_CALC_SIGNAL_BIT];     
                 endcase
             end
    end

    // cmd logic
    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
        begin
            cmd_clr_int_pulse_o <= 'b0;
            cmd_trigger_pulse_o <= 'b0;
        end
        else if (s_write)
             begin
                 case (s_w_word_addr)
                     `REG_CMD:
                     begin
                         if (s_wstrb[`CMD_CLR_INT_BIT / 8] && s_wdata[`CMD_CLR_INT_BIT] && ~cmd_clr_int_pulse_o)
                            cmd_clr_int_pulse_o <= 1'b1;
                         else
                            cmd_clr_int_pulse_o <= 1'b0;

                         if (s_wstrb[`CMD_TRIGGER_BIT / 8] && s_wdata[`CMD_TRIGGER_BIT] && ~cmd_trigger_pulse_o)
                            cmd_trigger_pulse_o <= 1'b1;
                         else
                            cmd_trigger_pulse_o <= 1'b0;

                     end
                 endcase
             end
             else
             begin
                 cmd_clr_int_pulse_o <= 'b0;
                 cmd_trigger_pulse_o <= 'b0;

             end
    end

    //
    // User reg read
    //
    // Reg Ctrl
    logic [slv.AXI_DATA_WIDTH - 1: 0] s_ctrl;

    always_comb
    begin
        s_ctrl = 'h0;
        s_ctrl[`CTRL_INT_EN_BIT] = ctrl_int_en_o;
    end

    // Reg Status
    logic [slv.AXI_DATA_WIDTH - 1: 0] s_status;

    always_comb
    begin
        s_status = 'h0;
        s_status[`STATUS_BUSY_BIT] = status_busy_i;
        s_status[`STATUS_INT_PENDING_BIT] = status_int_pending_i;
    end
//
    always_comb
    begin
        case (s_r_word_addr)
       	    `REG_CALC_HY_SGL:
                s_rdata = {'h0,!calc_Hy_end_flg_i};
            `REG_CALC_EZ_SGL:
                s_rdata = {'h0,!calc_Ez_end_flg_i};
            `REG_CALC_SRC_SGL:
                s_rdata = {'h0,!calc_src_end_flg_i};
            `REG_SIZE:
                // SystemVerilog will resize to the correct size
                s_rdata = {'h0, size_o};
            `REG_CTRL:
                s_rdata = s_ctrl;
            `REG_STATUS:
                s_rdata = s_status;
            default:
                s_rdata = 'h0;
        endcase
    end
//
endmodule
