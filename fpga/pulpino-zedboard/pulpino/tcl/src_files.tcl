set RTL ../../../rtl
set IPS ../../../ips
set FPGA_IPS ../ips
set FPGA_RTL ../rtl

proc findFiles { dir } { 
     global result
     if { [info exists result] } {
         set result $result
         } else {
             set result ""
         }
     set files [glob -nocomplain -directory $dir *]
     foreach f $files {
        if {[file isfile $f]} {             
                set fExt [file extension $f]    
                if {[expr {$fExt==".v"}] || [expr {$fExt==".vh"}] || [expr {$fExt==".vhd"}] || [expr {$fExt==".sv"}]} { 
                      if { "$result" == "" } {
                       set result "$f" 
                       } elseif { "$result" != "" } {    
                       set result "$result $f"      
                    }      
                    }                         
        } elseif {[file isdirectory $f]} {
            findFiles $f
        } 
    }
     return $result
}

# components
set SRC_COMPONENTS " \
   $RTL/components/fpga/pulp_clock_gating.sv \
   $RTL/components/fpga/cluster_clock_gating.sv \
   $RTL/components/fpga/cluster_clock_inverter.sv \
   $RTL/components/fpga/cluster_clock_mux2.sv \
   $RTL/components/rstgen.sv \
   $RTL/components/fpga/pulp_clock_inverter.sv \
   $RTL/components/fpga/pulp_clock_mux2.sv \
   $RTL/components/generic_fifo.sv \
"

# pulpino
set SRC_PULPINO " \
   $RTL/axi2apb_wrap.sv \
   $RTL/periph_bus_wrap.sv \
   $RTL/core2axi_wrap.sv \
   $RTL/axi_node_intf_wrap.sv \
   $RTL/axi_spi_slave_wrap.sv \
   $RTL/axi_slice_wrap.sv \
   $RTL/axi_mem_if_SP_wrap.sv \
   $RTL/core_region.sv \
   $RTL/instr_ram_wrap.sv \
   $RTL/sp_ram_wrap.sv \
   $RTL/boot_code.sv \
   $RTL/boot_rom_wrap.sv \
   $RTL/peripherals.sv \
   $RTL/ram_mux.sv \
   $RTL/pulpino_top.sv \
   $RTL/clk_rst_gen.sv \
   $FPGA_RTL/pulpino_wrap.v \
"

# user_plugin
set SRC_USER_PLUGIN [findFiles $RTL/user_plugin/rtl]
