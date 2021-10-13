// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module pulpino(
  clk,
  rst_n,

  fetch_enable_n,

  spi_clk_i,
  spi_cs_i,
  spi_sdo0_o,
  spi_sdi0_i,

  spi_master_clk_o,
  spi_master_csn0_o,
  spi_master_csn1_o,
  spi_master_csn2_o,
  spi_master_csn3_o,
  spi_master_sdo0_o,
  spi_master_sdi0_i,

  uart_tx,
  uart_rx,

  scl,
  sda,

  gpio,
  upio,

  tck_i,
  trstn_i,
  tms_i,
  tdi_i,
  tdo_o
  );

  // Clock and Reset
  input         clk;
  input         rst_n;

  input         fetch_enable_n;

  input         spi_clk_i;
  input         spi_cs_i;
  output        spi_sdo0_o;
  input         spi_sdi0_i;

  output        spi_master_clk_o;
  output        spi_master_csn0_o;
  output        spi_master_csn1_o;
  output        spi_master_csn2_o;
  output        spi_master_csn3_o;
  output        spi_master_sdo0_o;
  input         spi_master_sdi0_i;

  output        uart_tx;
  input         uart_rx;

  inout        scl;
  inout        sda;
  
  inout  [20:0] gpio;
  
  inout  [7:0]  upio;
  
  //IIC
  wire         scl_i;
  wire         scl_o;
  wire         scl_oen_o;
  wire         sda_i;
  wire         sda_o;
  wire         sda_oen_o;
  
  assign       scl_i = scl;
  assign       scl   = scl_oen_o ? 1'bz : scl_o;

  assign       sda_i = sda;
  assign       sda   = sda_oen_o ? 1'bz: sda_o;
  
  //gpio
  wire  [20:0] gpio_in;
  wire  [20:0] gpio_dir;
  wire  [20:0] gpio_out;
  
  assign gpio_in = gpio;
  genvar i;
  generate
    for (i = 0; i < 20; i = i + 1)
        begin: gen_gpio
           assign  gpio[i] = gpio_dir[i] ? gpio_out[i] : 1'bz;
        end
  endgenerate
 
  //upio
  wire  [7:0] upio_in;
  wire  [7:0] upio_dir;
  wire  [7:0] upio_out;
  
  assign upio_in = upio;
  generate
    for (i = 0; i < 7; i = i + 1)
        begin: gen_upio
           assign  upio[i] = upio_dir[i] ? upio_out[i] : 1'bz;
        end
  endgenerate
  
  // JTAG signals
  input  tck_i;
  input  trstn_i;
  input  tms_i;
  input  tdi_i;
  output tdo_o;

  parameter USE_ZERO_RISCY = 1;
  parameter RISCY_RV32F = 0;
  parameter ZERO_RV32M = 1;
  parameter ZERO_RV32E = 0;
   
  reg          usr_clk;
  reg   [3:0]  usr_cnt;
  
  reg [3:0] counter;
  always@(posedge clk or negedge rst_n) begin
  if(!rst_n)
    counter <= 4'd0;
  else if(counter==4'd4)
    counter <= 4'd0;
  else
    counter <= counter + 1'd1;
  end

  always@(posedge clk or negedge rst_n) begin
  if(!rst_n)
    usr_clk <= 4'd0;
  else if(counter==4'd4)
    usr_clk <= ~usr_clk;
  else
    usr_clk <= usr_clk;
  end

  // PULP SoC
  pulpino_top
  #(
    .USE_ZERO_RISCY    ( USE_ZERO_RISCY ),
    .RISCY_RV32F       ( RISCY_RV32F    ),
    .ZERO_RV32M        ( ZERO_RV32M     ),
    .ZERO_RV32E        ( ZERO_RV32E     )
  )
  pulpino_i
  (
    .clk               ( usr_clk           ),//5MHz
    .rst_n             ( rst_n             ),

    .clk_sel_i         ( 1'b0              ),
    .clk_standalone_i  ( 1'b0              ),

    .testmode_i        ( 1'b0              ),
    .fetch_enable_i    ( fetch_enable_n   ),
    .scan_enable_i     ( 1'b0              ),

    .spi_clk_i         ( spi_clk_i         ), 
    .spi_cs_i          ( spi_cs_i          ),
    .spi_mode_o        (                   ),
    .spi_sdo0_o        ( spi_sdo0_o        ),
    .spi_sdo1_o        (                   ),
    .spi_sdo2_o        (                   ),
    .spi_sdo3_o        (                   ),
    .spi_sdi0_i        ( spi_sdi0_i        ),
    .spi_sdi1_i        ( 1'b0              ),
    .spi_sdi2_i        ( 1'b0              ),
    .spi_sdi3_i        ( 1'b0              ),

    .spi_master_clk_o  ( spi_master_clk_o  ),
    .spi_master_csn0_o ( spi_master_csn0_o ),
    .spi_master_csn1_o ( spi_master_csn1_o ),
    .spi_master_csn2_o ( spi_master_csn2_o ),
    .spi_master_csn3_o ( spi_master_csn3_o ),
    .spi_master_mode_o (                   ),
    .spi_master_sdo0_o ( spi_master_sdo0_o ),
    .spi_master_sdo1_o (                   ),
    .spi_master_sdo2_o (                   ),
    .spi_master_sdo3_o (                   ),
    .spi_master_sdi0_i ( spi_master_sdi0_i ),
    .spi_master_sdi1_i ( 1'b0              ),
    .spi_master_sdi2_i ( 1'b0              ),
    .spi_master_sdi3_i ( 1'b0              ),

    .uart_tx           ( uart_tx           ), // output
    .uart_rx           ( uart_rx           ), // input
    .uart_rts          (                   ), // output
    .uart_dtr          (                   ), // output
    .uart_cts          ( 1'b0              ), // input
    .uart_dsr          ( 1'b0              ), // input

    .scl_pad_i         ( scl_i             ),
    .scl_pad_o         ( scl_o             ),
    .scl_padoen_o      ( scl_oen_o         ),
    .sda_pad_i         ( sda_i             ),
    .sda_pad_o         ( sda_o             ),
    .sda_padoen_o      ( sda_oen_o         ),

    .gpio_in           ( gpio_in           ),
    .gpio_out          ( gpio_out          ),
    .gpio_dir          ( gpio_dir          ),
    .gpio_padcfg       (                   ),
    
    .upio_in_i         ( upio_in           ),
    .upio_out_o        ( upio_out          ),
    .upio_dir_o        ( upio_dir          ),

    .tck_i             ( tck_i             ),
    .trstn_i           ( trstn_i           ),
    .tms_i             ( tms_i             ),
    .tdi_i             ( tdi_i             ),
    .tdo_o             ( tdo_o             ),

    .pad_cfg_o         (                   ),
    .pad_mux_o         (                   )
  );

endmodule
