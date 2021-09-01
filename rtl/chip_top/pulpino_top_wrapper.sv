module pulpino_top_wrapper
  #(
    parameter USE_ZERO_RISCY       = 1,
    parameter RISCY_RV32F          = 0,
    parameter ZERO_RV32M           = 1,
    parameter ZERO_RV32E           = 0
  )
  (
    // Clock and Reset
    input  logic              clk /*verilator clocker*/,
    output logic              clk_pad_tie0,
    output logic              clk_pad_tie1,
    input  logic              rst_n,
    output logic              rst_n_pad_tie0,
    output logic              rst_n_pad_tie1,
    output logic              rst_n_pad_OEN_1,
    output logic              rst_n_pad_I_0,

    input  logic              fetch_enable_i,
    output logic              fetch_enable_pad_tie0,
    output logic              fetch_enable_pad_tie1,
    output logic              fetch_enable_pad_OEN_1,
    output logic              fetch_enable_pad_I_0,

    //SPI Slave
    input  logic              spi_clk_i /*verilator clocker*/,
    output logic              spi_clk_pad_tie0,
    output logic              spi_clk_pad_tie1,
    output logic              spi_clk_pad_OEN_1,
    output logic              spi_clk_pad_I_0,
    input  logic              spi_cs_i /*verilator clocker*/,
    output logic              spi_cs_pad_tie0,
    output logic              spi_cs_pad_tie1,
    output logic              spi_cs_pad_OEN_1,
    output logic              spi_cs_pad_I_0,
    output logic [1:0]        spi_mode_o,
    output logic              spi_sdo0_o,
    output logic              spi_miso_pad_tie0,
    output logic              spi_miso_pad_tie1,
    output logic              spi_miso_pad_OEN_0,
    output logic              spi_sdo1_o,
    output logic              spi_sdo2_o,
    output logic              spi_sdo3_o,
    input  logic              spi_sdi0_i,
    output logic              spi_mosi_pad_tie0,
    output logic              spi_mosi_pad_tie1,
    output logic              spi_mosi_pad_OEN_1,
    output logic              spi_mosi_pad_I_0,

    //SPI Master
    output logic              spi_master_clk_o,
    output logic              spi_master_clk_pad_tie0,
    output logic              spi_master_clk_pad_tie1,
    output logic              spi_master_clk_pad_OEN_0,
    output logic              spi_master_csn0_o,
    output logic              spi_master_csn0_pad_tie0,
    output logic              spi_master_csn0_pad_tie1,
    output logic              spi_master_csn0_pad_OEN_0,
    output logic              spi_master_csn1_o,
    output logic              spi_master_csn1_pad_tie0,
    output logic              spi_master_csn1_pad_tie1,
    output logic              spi_master_csn1_pad_OEN_0,
    output logic              spi_master_csn2_o,
    output logic              spi_master_csn2_pad_tie0,
    output logic              spi_master_csn2_pad_tie1,
    output logic              spi_master_csn2_pad_OEN_0,
    output logic              spi_master_csn3_o,
    output logic              spi_master_csn3_pad_tie0,
    output logic              spi_master_csn3_pad_tie1,
    output logic              spi_master_csn3_pad_OEN_0,
    output logic [1:0]        spi_master_mode_o,
    output logic              spi_master_sdo0_o,
    output logic              spi_master_mosi_pad_tie0,
    output logic              spi_master_mosi_pad_tie1,
    output logic              spi_master_mosi_pad_OEN_0,
    output logic              spi_master_sdo1_o,
    output logic              spi_master_sdo2_o,
    output logic              spi_master_sdo3_o,
    input  logic              spi_master_sdi0_i,
    output logic              spi_master_miso_pad_tie0,
    output logic              spi_master_miso_pad_tie1,
    output logic              spi_master_miso_pad_OEN_1,
    output logic              spi_master_miso_pad_I_0,

    input  logic              scl_pad_i,
    output logic              scl_pad_o,
    output logic              scl_pad_tie0,
    output logic              scl_pad_tie1,
    output logic              scl_padoen_o,
    input  logic              sda_pad_i,
    output logic              sda_pad_o,
    output logic              sda_pad_tie0,
    output logic              sda_pad_tie1,
    output logic              sda_padoen_o,

    output logic              uart_tx,
    output logic              uart_tx_pad_tie0,
    output logic              uart_tx_pad_tie1,
    output logic              uart_tx_pad_OEN_0,
    input  logic              uart_rx,
    output logic              uart_rx_pad_tie0,
    output logic              uart_rx_pad_tie1,
    output logic              uart_rx_pad_OEN_1,
    output logic              uart_rx_pad_I_0,
    output logic              uart_rts,
    output logic              uart_dtr,

    input  logic       [20:0] gpio_in,
    output logic       [31:0] gpio_out,
    output logic       [31:0] gpio_pad_tie0,
    output logic       [31:0] gpio_pad_tie1,
    output logic       [31:0] gpio_pad_OEN,
    output logic [31:0] [5:0] gpio_padcfg,

    input  logic        [7:0] upio_in_i,
    output logic        [7:0] upio_out_o,
    output logic        [7:0] upio_pad_tie0,
    output logic        [7:0] upio_pad_tie1,
    output logic        [7:0] upio_pad_OEN,

    // JTAG signals
    input  logic              tck_i,
    output logic              tck_pad_tie0,
    output logic              tck_pad_tie1,
    output logic              tck_pad_OEN_1,
    output logic              tck_pad_I_0,
    input  logic              trstn_i,
    output logic              trstn_pad_tie0,
    output logic              trstn_pad_tie1,
    output logic              trstn_pad_OEN_1,
    output logic              trstn_pad_I_0,
    input  logic              tms_i,
    output logic              tms_pad_tie0,
    output logic              tms_pad_tie1,
    output logic              tms_pad_OEN_1,
    output logic              tms_pad_I_0,
    input  logic              tdi_i,
    output logic              tdi_pad_tie0,
    output logic              tdi_pad_tie1,
    output logic              tdi_pad_OEN_1,
    output logic              tdi_pad_I_0,
    output logic              tdo_o,
    output logic              tdo_pad_tie0,
    output logic              tdo_pad_tie1,
    output logic              tdo_pad_OEN_0,

    // PULPino specific pad config
    output logic [31:0] [5:0] pad_cfg_o,
    output logic       [31:0] pad_mux_o
  );

  logic [31:0] gpio_in_wrapper;
  assign gpio_in_wrapper = {11'b0, gpio_in};

  logic [31:0] gpio_dir;
  assign gpio_pad_OEN = ~gpio_dir;

  logic [7:0] upio_dir_o;
  assign upio_pad_OEN = ~upio_dir_o;

  pulpino_top #(
    .USE_ZERO_RISCY(USE_ZERO_RISCY),
    .RISCY_RV32F(RISCY_RV32F),
    .ZERO_RV32M(ZERO_RV32M),
    .ZERO_RV32E(ZERO_RV32E)
  ) pulpino_top_i (
    .clk_sel_i         ( 1'b0            ),
    .clk_standalone_i  ( 1'b0            ),
    .testmode_i        ( 1'b0            ),
    .scan_enable_i     ( 1'b0            ),
    .spi_sdi1_i        ( 1'b0            ),
    .spi_sdi2_i        ( 1'b0            ),
    .spi_sdi3_i        ( 1'b0            ),
    .spi_master_sdi1_i ( 1'b0            ),
    .spi_master_sdi2_i ( 1'b0            ),
    .spi_master_sdi3_i ( 1'b0            ),
    .uart_cts          ( 1'b0            ),
    .uart_dsr          ( 1'b0            ),
    .gpio_in           ( gpio_in_wrapper ),
    .*
    );

  assign clk_pad_tie0             = 1'b0;
  assign clk_pad_tie1             = 1'b1;

  assign rst_n_pad_tie0           = 1'b0;
  assign rst_n_pad_tie1           = 1'b1;
  assign rst_n_pad_OEN_1          = 1'b1;
  assign rst_n_pad_I_0            = 1'b0;

  assign fetch_enable_pad_tie0    = 1'b0;
  assign fetch_enable_pad_tie1    = 1'b1;
  assign fetch_enable_pad_OEN_1   = 1'b1;
  assign fetch_enable_pad_I_0     = 1'b0;

  assign spi_clk_pad_tie0         = 1'b0;
  assign spi_clk_pad_tie1         = 1'b1;
  assign spi_clk_pad_OEN_1        = 1'b1;
  assign spi_clk_pad_I_0          = 1'b0;

  assign spi_cs_pad_tie0          = 1'b0;
  assign spi_cs_pad_tie1          = 1'b1;
  assign spi_cs_pad_OEN_1         = 1'b1;
  assign spi_cs_pad_I_0           = 1'b0;

  assign spi_miso_pad_tie0        = 1'b0;
  assign spi_miso_pad_tie1        = 1'b1;
  assign spi_miso_pad_OEN_0       = 1'b0;

  assign spi_mosi_pad_tie0        = 1'b0;
  assign spi_mosi_pad_tie1        = 1'b1;
  assign spi_mosi_pad_OEN_1       = 1'b1;
  assign spi_mosi_pad_I_0         = 1'b0;

  assign spi_master_clk_pad_tie0   = 1'b0;
  assign spi_master_clk_pad_tie1   = 1'b1;
  assign spi_master_clk_pad_OEN_0  = 1'b0;
  assign spi_master_csn0_pad_tie0  = 1'b0;
  assign spi_master_csn0_pad_tie1  = 1'b1;
  assign spi_master_csn0_pad_OEN_0 = 1'b0;
  assign spi_master_csn1_pad_tie0  = 1'b0;
  assign spi_master_csn1_pad_tie1  = 1'b1;
  assign spi_master_csn1_pad_OEN_0 = 1'b0;
  assign spi_master_csn2_pad_tie0  = 1'b0;
  assign spi_master_csn2_pad_tie1  = 1'b1;
  assign spi_master_csn2_pad_OEN_0 = 1'b0;
  assign spi_master_csn3_pad_tie0  = 1'b0;
  assign spi_master_csn3_pad_tie1  = 1'b1;
  assign spi_master_csn3_pad_OEN_0 = 1'b0;
  assign spi_master_mosi_pad_tie0  = 1'b0;
  assign spi_master_mosi_pad_tie1  = 1'b1;
  assign spi_master_mosi_pad_OEN_0 = 1'b0;
  assign spi_master_miso_pad_tie0  = 1'b0;
  assign spi_master_miso_pad_tie1  = 1'b1;
  assign spi_master_miso_pad_OEN_1 = 1'b1;
  assign spi_master_miso_pad_I_0   = 1'b0;

  assign scl_pad_tie0              = 1'b0;
  assign scl_pad_tie1              = 1'b1;
  assign sda_pad_tie0              = 1'b0;
  assign sda_pad_tie1              = 1'b1;

  assign uart_tx_pad_tie0          = 1'b0;
  assign uart_tx_pad_tie1          = 1'b1;
  assign uart_tx_pad_OEN_0         = 1'b0;
  assign uart_rx_pad_tie0          = 1'b0;
  assign uart_rx_pad_tie1          = 1'b1;
  assign uart_rx_pad_OEN_1         = 1'b1;
  assign uart_rx_pad_I_0           = 1'b0;

  assign gpio_pad_tie0             = 32'h0000_0000;
  assign gpio_pad_tie1             = 32'hFFFF_FFFF;

  assign upio_pad_tie0             = 8'h00;
  assign upio_pad_tie1             = 8'hFF;

  assign tck_pad_tie0              = 1'b0;
  assign tck_pad_tie1              = 1'b1;
  assign tck_pad_OEN_1             = 1'b1;
  assign tck_pad_I_0               = 1'b0;

  assign trstn_pad_tie0            = 1'b0;
  assign trstn_pad_tie1            = 1'b1;
  assign trstn_pad_OEN_1           = 1'b1;
  assign trstn_pad_I_0             = 1'b0;

  assign tms_pad_tie0              = 1'b0;
  assign tms_pad_tie1              = 1'b1;
  assign tms_pad_OEN_1             = 1'b1;
  assign tms_pad_I_0               = 1'b0;

  assign tdi_pad_tie0              = 1'b0;
  assign tdi_pad_tie1              = 1'b1;
  assign tdi_pad_OEN_1             = 1'b1;
  assign tdi_pad_I_0               = 1'b0;

  assign tdo_pad_tie0              = 1'b0;
  assign tdo_pad_tie1              = 1'b1;
  assign tdo_pad_OEN_0             = 1'b0;

endmodule
