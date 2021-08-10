
`include "exit_status.sv"

`define REF_CLK_PERIOD   (2*15.25us)  // 32.786 kHz --> FLL reset value --> 50 MHz
`define CLK_PERIOD       40.00ns      // 25 MHz

module tb;
  timeunit      1ns;
  timeprecision 1ps;

  // +MEMLOAD= valid values are "SPI", "STANDALONE" "PRELOAD", "" (no load of L2)
  // parameter  SPI            = "QUAD";    // valid values are "SINGLE", "QUAD"
  parameter  SPI             = "SINGLE";    // valid values are "SINGLE", "QUAD"
  parameter  BAUDRATE        = 781250;    // 1562500
  parameter  CLK_USE_FLL     = 0;  // 0 or 1
  parameter  TEST            = ""; //valid values are "" (NONE), "DEBUG"

  parameter  USE_ZERO_RISCY  = 0;
  parameter  RISCY_RV32F     = 0;
  parameter  ZERO_RV32M      = 1;
  parameter  ZERO_RV32E      = 0;

  
  int  exit_status = `EXIT_ERROR; // modelsim exit code, will be overwritten when successful

  logic         s_clk   = 1'b0;

  generate
    if (CLK_USE_FLL) begin
      initial
      begin
        #(`REF_CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`REF_CLK_PERIOD/2) ~s_clk;
      end
    end else begin
      initial
      begin
        #(`CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`CLK_PERIOD/2) ~s_clk;
      end
    end
  endgenerate

  ExitStatus exit_status_if();
  tb_chip_top
  #(
    .SPI               ( SPI            ),
    .BAUDRATE          ( BAUDRATE       ),
    .TEST              ( TEST           ),

    .DUT_IMPL          ( "NORMAL"       ),
    .USE_ZERO_RISCY    ( USE_ZERO_RISCY ),
    .RISCY_RV32F       ( RISCY_RV32F    ),
    .ZERO_RV32M        ( ZERO_RV32M     ),
    .ZERO_RV32E        ( ZERO_RV32E     )
  ) tb_chip_top_i(
    .s_clk(s_clk),
    .exit_status_if(exit_status_if)
  );

  initial begin
    exit_status = 0;

    wait(exit_status_if.done);
    if (exit_status_if.status != pkg_exit_status::SUCCESS) begin
      exit_status = -1;
    end

    $fflush();
    $finish;
  end

endmodule
