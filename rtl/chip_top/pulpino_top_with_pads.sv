// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "axi_bus.sv"
`include "debug_bus.sv"

`define AXI_ADDR_WIDTH         32
`define AXI_DATA_WIDTH         32
`define AXI_ID_MASTER_WIDTH     2
`define AXI_ID_SLAVE_WIDTH      4
`define AXI_USER_WIDTH          1

module pulpino_top_with_pads
  #(
    parameter USE_ZERO_RISCY       = 1,
    parameter RISCY_RV32F          = 0,
    parameter ZERO_RV32M           = 1,
    parameter ZERO_RV32E           = 0
  )
  (
    // Clock and Reset
    inout  wire              clk_pad,
    inout  wire              rst_n_pad,

    inout  wire              fetch_enable_pad,

    //SPI Slave
    inout  wire              spi_clk_pad,
    inout  wire              spi_cs_pad,
    inout  wire              spi_miso_pad,
    inout  wire              spi_mosi_pad,

    //SPI Master
    inout  wire              spi_master_clk_pad,
    inout  wire              spi_master_csn0_pad,
    inout  wire              spi_master_csn1_pad,
    inout  wire              spi_master_csn2_pad,
    inout  wire              spi_master_csn3_pad,
    inout  wire              spi_master_miso_pad,
    inout  wire              spi_master_mosi_pad,

    inout  wire              scl_pad,
    inout  wire              sda_pad,

    inout  wire              uart_tx_pad,
    inout  wire              uart_rx_pad,

    inout  wire       [20:0] gpio_pad,

    inout  wire        [7:0] upio_pad,

    // JTAG signals
    inout  wire              tck_pad,
    inout  wire              trstn_pad,
    inout  wire              tms_pad,
    inout  wire              tdi_pad,
    inout  wire              tdo_pad
  );
    // Clock and Reset
    logic              clk /*verilator clocker*/;
    logic              clk_pad_tie0;
    logic              clk_pad_tie1;
    logic              rst_n;
    logic              rst_n_pad_tie0;
    logic              rst_n_pad_tie1;
    logic              rst_n_pad_OEN_1;
    logic              rst_n_pad_I_0;

    logic              fetch_enable_i;
    logic              fetch_enable_pad_tie0;
    logic              fetch_enable_pad_tie1;
    logic              fetch_enable_pad_OEN_1;
    logic              fetch_enable_pad_I_0;

    //SPI Slave
    logic              spi_clk_i /*verilator clocker*/;
    logic              spi_clk_pad_tie0;
    logic              spi_clk_pad_tie1;
    logic              spi_clk_pad_OEN_1;
    logic              spi_clk_pad_I_0;
    logic              spi_cs_i /*verilator clocker*/;
    logic              spi_cs_pad_tie0;
    logic              spi_cs_pad_tie1;
    logic              spi_cs_pad_OEN_1;
    logic              spi_cs_pad_I_0;
    logic [1:0]        spi_mode_o;
    logic              spi_sdo0_o;
    logic              spi_miso_pad_tie0;
    logic              spi_miso_pad_tie1;
    logic              spi_miso_pad_OEN_0;
    logic              spi_sdo1_o;
    logic              spi_sdo2_o;
    logic              spi_sdo3_o;
    logic              spi_sdi0_i;
    logic              spi_mosi_pad_tie0;
    logic              spi_mosi_pad_tie1;
    logic              spi_mosi_pad_OEN_1;
    logic              spi_mosi_pad_I_0;

    //SPI Master
    logic              spi_master_clk_o;
    logic              spi_master_clk_pad_tie0;
    logic              spi_master_clk_pad_tie1;
    logic              spi_master_clk_pad_OEN_0;
    logic              spi_master_csn0_o;
    logic              spi_master_csn0_pad_tie0;
    logic              spi_master_csn0_pad_tie1;
    logic              spi_master_csn0_pad_OEN_0;
    logic              spi_master_csn1_o;
    logic              spi_master_csn1_pad_tie0;
    logic              spi_master_csn1_pad_tie1;
    logic              spi_master_csn1_pad_OEN_0;
    logic              spi_master_csn2_o;
    logic              spi_master_csn2_pad_tie0;
    logic              spi_master_csn2_pad_tie1;
    logic              spi_master_csn2_pad_OEN_0;
    logic              spi_master_csn3_o;
    logic              spi_master_csn3_pad_tie0;
    logic              spi_master_csn3_pad_tie1;
    logic              spi_master_csn3_pad_OEN_0;
    logic [1:0]        spi_master_mode_o;
    logic              spi_master_sdo0_o;
    logic              spi_master_mosi_pad_tie0;
    logic              spi_master_mosi_pad_tie1;
    logic              spi_master_mosi_pad_OEN_0;
    logic              spi_master_sdo1_o;
    logic              spi_master_sdo2_o;
    logic              spi_master_sdo3_o;
    logic              spi_master_sdi0_i;
    logic              spi_master_miso_pad_tie0;
    logic              spi_master_miso_pad_tie1;
    logic              spi_master_miso_pad_OEN_1;
    logic              spi_master_miso_pad_I_0;

    logic              scl_pad_i;
    logic              scl_pad_o;
    logic              scl_pad_tie0;
    logic              scl_pad_tie1;
    logic              scl_padoen_o;
    logic              sda_pad_i;
    logic              sda_pad_o;
    logic              sda_pad_tie0;
    logic              sda_pad_tie1;
    logic              sda_padoen_o;

    logic              uart_tx;
    logic              uart_tx_pad_tie0;
    logic              uart_tx_pad_tie1;
    logic              uart_tx_pad_OEN_0;
    logic              uart_rx;
    logic              uart_rx_pad_tie0;
    logic              uart_rx_pad_tie1;
    logic              uart_rx_pad_OEN_1;
    logic              uart_rx_pad_I_0;
    logic              uart_rts;
    logic              uart_dtr;

    logic       [20:0] gpio_in;
    logic       [31:0] gpio_out;
    logic       [31:0] gpio_pad_tie0;
    logic       [31:0] gpio_pad_tie1;
    logic       [31:0] gpio_pad_OEN;
    logic [31:0] [5:0] gpio_padcfg;

    logic        [7:0] upio_in;
    logic        [7:0] upio_out;
    logic        [7:0] upio_pad_tie0;
    logic        [7:0] upio_pad_tie1;
    logic        [7:0] upio_pad_OEN;

    // JTAG signals
    logic              tck_i;
    logic              tck_pad_tie0;
    logic              tck_pad_tie1;
    logic              tck_pad_OEN_1;
    logic              tck_pad_I_0;
    logic              trstn_i;
    logic              trstn_pad_tie0;
    logic              trstn_pad_tie1;
    logic              trstn_pad_OEN_1;
    logic              trstn_pad_I_0;
    logic              tms_i;
    logic              tms_pad_tie0;
    logic              tms_pad_tie1;
    logic              tms_pad_OEN_1;
    logic              tms_pad_I_0;
    logic              tdi_i;
    logic              tdi_pad_tie0;
    logic              tdi_pad_tie1;
    logic              tdi_pad_OEN_1;
    logic              tdi_pad_I_0;
    logic              tdo_pad_tie0;
    logic              tdo_pad_tie1;
    logic              tdo_o;
    logic              tdo_pad_OEN_0;

    // PULPino specific pad config
    logic [31:0] [5:0] pad_cfg_o;
    logic       [31:0] pad_mux_o;

  pulpino_pads pulpino_pads_i(
    .gpio_in       ( gpio_in[20:0]       ),
    .gpio_out      ( gpio_out[20:0]      ),
    .gpio_pad_tie0 ( gpio_pad_tie0[20:0] ),
    .gpio_pad_tie1 ( gpio_pad_tie1[20:0] ),
    .gpio_pad_OEN  ( gpio_pad_OEN[20:0]  ),
    .gpio_pad      ( gpio_pad            ),

    .upio_in       ( upio_in             ),
    .upio_out      ( upio_out            ),
    .upio_pad_tie0 ( upio_pad_tie0       ),
    .upio_pad_tie1 ( upio_pad_tie1       ),
    .upio_pad_OEN  ( upio_pad_OEN        ),
    .upio_pad      ( upio_pad            ),

    .*
    );

  pulpino_top_wrapper #(
    .USE_ZERO_RISCY(USE_ZERO_RISCY),
    .RISCY_RV32F(RISCY_RV32F),
    .ZERO_RV32M(ZERO_RV32M),
    .ZERO_RV32E(ZERO_RV32E)
  ) top_wrapper_i (
    .upio_in_i     ( upio_in       ),
    .upio_out_o    ( upio_out      ),
    .upio_pad_tie0 ( upio_pad_tie0 ),
    .upio_pad_tie1 ( upio_pad_tie1 ),
    .upio_pad_OEN  ( upio_pad_OEN  ),

    .*
    );

endmodule

