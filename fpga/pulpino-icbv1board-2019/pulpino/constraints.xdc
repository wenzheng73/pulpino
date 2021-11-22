create_clock -period 20.000 -name clk [get_ports clk]

set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS15} [get_ports fetch_enable_n]
set_property PULLDOWN true [get_ports fetch_enable_n]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS15} [get_ports rst_n]
set_property PULLDOWN true [get_ports rst_n]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS15} [get_ports clk]
set_property PULLDOWN true [get_ports clk]
#set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS15} [get_ports key[3]]

#spi
set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS15} [get_ports spi_cs_i]
set_property PULLDOWN true [get_ports spi_cs_i]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS15} [get_ports {spi_mode_o[0]}]
set_property PULLDOWN true [get_ports spi_mode_o[0]]
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS15} [get_ports {spi_mode_o[1]}]
set_property PULLDOWN true [get_ports spi_mode_o[1]]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS15} [get_ports spi_sdo0_o]
set_property PULLDOWN true [get_ports spi_sdo0_o]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS15} [get_ports spi_sdo1_o]
set_property PULLDOWN true [get_ports spi_sdo1_o]
set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS15} [get_ports spi_sdo2_o]
set_property PULLDOWN true [get_ports spi_sdo2_o]
set_property -dict {PACKAGE_PIN Y2 IOSTANDARD LVCMOS15} [get_ports spi_sdo3_o]
set_property PULLDOWN true [get_ports spi_sdo3_o]
set_property -dict {PACKAGE_PIN W1 IOSTANDARD LVCMOS15} [get_ports spi_sdi0_i]
set_property PULLDOWN true [get_ports spi_sdi0_i]
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD LVCMOS15} [get_ports spi_sdi1_i]
set_property PULLDOWN true [get_ports spi_sdi1_i]
set_property -dict {PACKAGE_PIN U3 IOSTANDARD LVCMOS15} [get_ports spi_sdi2_i]
set_property PULLDOWN true [get_ports spi_sdi2_i]
set_property -dict {PACKAGE_PIN V3 IOSTANDARD LVCMOS15} [get_ports spi_sdi3_i]
set_property PULLDOWN true [get_ports spi_sdi3_i]
#spi master
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVCMOS15} [get_ports spi_master_clk_o]
set_property PULLDOWN true [get_ports spi_master_clk_o]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS15} [get_ports spi_master_csn0_o]
set_property PULLDOWN true [get_ports spi_master_csn0_o]
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD LVCMOS15} [get_ports spi_master_csn1_o]
set_property PULLDOWN true [get_ports spi_master_csn1_o]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS15} [get_ports spi_master_csn2_o]
set_property PULLDOWN true [get_ports spi_master_csn2_o]
set_property -dict {PACKAGE_PIN Y3 IOSTANDARD LVCMOS15} [get_ports spi_master_csn3_o]
set_property PULLDOWN true [get_ports spi_master_csn3_o]
set_property -dict {PACKAGE_PIN AA3 IOSTANDARD LVCMOS15} [get_ports {spi_master_mode_o[0]}]
set_property PULLDOWN true [get_ports spi_master_mode_o[0]]
set_property -dict {PACKAGE_PIN AA5 IOSTANDARD LVCMOS15} [get_ports {spi_master_mode_o[1]}]
set_property PULLDOWN true [get_ports spi_master_mode_o[1]]
set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS15} [get_ports spi_master_sdo0_o]
set_property PULLDOWN true [get_ports spi_master_sdo0_o]
set_property -dict {PACKAGE_PIN Y4 IOSTANDARD LVCMOS15} [get_ports spi_master_sdo1_o]
set_property PULLDOWN true [get_ports spi_master_sdo1_o]
set_property -dict {PACKAGE_PIN AA4 IOSTANDARD LVCMOS15} [get_ports spi_master_sdo2_o] 
set_property PULLDOWN true [get_ports spi_master_sdo2_o]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS15} [get_ports spi_master_sdo3_o]
set_property PULLDOWN true [get_ports spi_master_sdo3_o]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS15} [get_ports spi_master_sdi0_i]
set_property PULLDOWN true [get_ports spi_master_sdi0_i]
set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS15} [get_ports spi_master_sdi1_i]
set_property PULLDOWN true [get_ports spi_master_sdi1_i]
set_property -dict {PACKAGE_PIN A1 IOSTANDARD LVCMOS15} [get_ports spi_master_sdi2_i]
set_property PULLDOWN true [get_ports spi_master_sdi2_i]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS15} [get_ports spi_master_sdi3_i]
set_property PULLDOWN true [get_ports spi_master_sdi3_i]
#uart
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS15} [get_ports uart_tx]
set_property PULLDOWN true [get_ports uart_tx]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS15} [get_ports uart_rx]
set_property PULLDOWN true [get_ports uart_rx]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS15} [get_ports uart_rts]
set_property PULLDOWN true [get_ports uart_rts]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS15} [get_ports uart_dtr]
set_property PULLDOWN true [get_ports uart_dtr]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS15} [get_ports uart_cts]
set_property PULLDOWN true [get_ports uart_cts]
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS15} [get_ports uart_dsr]
set_property PULLDOWN true [get_ports uart_dsr]
#sd scl
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS15} [get_ports scl_i]
set_property PULLDOWN true [get_ports scl_i]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS15} [get_ports scl_o]
set_property PULLDOWN true [get_ports scl_o]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS15} [get_ports scl_oen_o]
set_property PULLDOWN true [get_ports scl_oen_o]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS15} [get_ports sda_i]
set_property PULLDOWN true [get_ports sda_i]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS15} [get_ports sda_o]
set_property PULLDOWN true [get_ports sda_o]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS15} [get_ports sda_oen_o]
set_property PULLDOWN true [get_ports sda_oen_o]
#gpio
set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS15} [get_ports {gpio_out[0]}]
set_property PULLDOWN true [get_ports gpio_out[0]]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS15} [get_ports {gpio_out[1]}]
set_property PULLDOWN true [get_ports gpio_out[1]]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS15} [get_ports {gpio_out[2]}]
set_property PULLDOWN true [get_ports gpio_out[2]]
set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS15} [get_ports {gpio_out[3]}]
set_property PULLDOWN true [get_ports gpio_out[3]]
#JTAG
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports trstn_i]
set_property PULLDOWN true [get_ports trstn_i]
set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS33} [get_ports tms_i]
set_property PULLDOWN true [get_ports tms_i]
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports tdi_i]
set_property PULLDOWN true [get_ports tdi_i]
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS33} [get_ports tdo_o]
set_property PULLDOWN true [get_ports tdo_o]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33}  [get_ports tck_i]
set_property PULLDOWN true [get_ports tck_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets tck_i_IBUF]


set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]
