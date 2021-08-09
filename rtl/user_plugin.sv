
module user_plugin
(
    // Common clk/rst
    input logic        clk_i,
    input logic        rst_n,

    APB_BUS.Slave      apb_slv,
    AXI_BUS.Slave      axi_slv,
    AXI_BUS.Master     axi_mstr,

    input  logic [7:0] upio_in_i,
    output logic [7:0] upio_out_o,
    output logic [7:0] upio_dir_o,

    // Interupt signal
    output logic  int_o
);  

    logic apb_up_int_o;
    logic axi_up_int_o;
    logic fdtd_up_int_o;

    assign int_o = apb_up_int_o | axi_up_int_o|fdtd_up_int_o;
    
    apb_up 
    #(
        .APB_ADDR_WIDTH(12)
    )
    apb_up_i
    (
        .HCLK       ( clk_i               ),
        .HRESETn    ( rst_n               ),

        .PADDR      ( apb_slv.paddr[11:0] ),
        .PWDATA     ( apb_slv.pwdata      ),
        .PWRITE     ( apb_slv.pwrite      ),
        .PSEL       ( apb_slv.psel        ),
        .PENABLE    ( apb_slv.penable     ),
        .PRDATA     ( apb_slv.prdata      ),
        .PREADY     ( apb_slv.pready      ),
        .PSLVERR    ( apb_slv.pslverr     ),

        .upio_in_i  ( upio_in_i           ),
        .upio_out_o ( upio_out_o          ),
        .upio_dir_o ( upio_dir_o          ),

        .int_o      ( apb_up_int_o        )
    );

    /*axi_up axi_up_i
    (
        .ACLK    ( clk_i        ),
        .ARESETn ( rst_n        ),
        .slv     ( axi_slv      ),
        .mstr    ( axi_mstr     ),
        .int_o   ( axi_up_int_o )
    );*/
    
    fdtd_top fdtd_top_i
    (
        .ACLK    ( clk_i        ),
        .ARESETn ( rst_n        ),
        .slv     ( axi_slv      ),
        .mstr    ( axi_mstr     ),
        .int_o   ( fdtd_up_int_o )
        
      );
endmodule
