#!/bin/tcsh
source ${PULP_PATH}/vsim/vcompile/colors.csh

##############################################################################
# Settings
##############################################################################

set IP=pulpino
set IP_NAME="PULPino"


##############################################################################
# Check settings
##############################################################################

# check if environment variables are defined
if (! $?MSIM_LIBS_PATH ) then
  echo "${Red} MSIM_LIBS_PATH is not defined ${NC}"
  exit 1
endif

if (! $?VIP_PATH ) then
  echo "${Red} VIP_PATH is not defined ${NC}"
  exit 1
endif

if (! $?RTL_PATH ) then
  echo "${Red} RTL_PATH is not defined ${NC}"
  exit 1
endif

if (! $?PROCESS ) then
  echo "${Red} PROCESS is not defined ${NC}"
  exit 1
endif


set LIB_NAME="${IP}_lib"
set LIB_PATH="${MSIM_LIBS_PATH}/${LIB_NAME}"

##############################################################################
# Preparing library
##############################################################################

echo "${Green}--> Compiling ${IP_NAME}... ${NC}"

rm -rf $LIB_PATH

vlib $LIB_PATH
vmap $LIB_NAME $LIB_PATH

echo "${Green}Compiling component: ${Brown} ${IP_NAME} ${NC}"
echo "${Red}"

##############################################################################
# Compiling RTL
##############################################################################

# decide if we want to build for riscv or or1k
if ( ! $?PULP_CORE) then
  set PULP_CORE="riscv"
endif

if ( $PULP_CORE == "riscv" ) then
  set CORE_DEFINES=+define+RISCV
  echo "${Yellow} Compiling for RISCV core ${NC}"
else
  set CORE_DEFINES=+define+OR10N
  echo "${Yellow} Compiling for OR10N core ${NC}"
endif

# decide if we want to build for riscv or or1k
if ( ! $?ASIC_DEFINES) then
  set ASIC_DEFINES=""
endif

echo "Compiling Process Files ..."
# C shell does not support function
set PROCESS_DIR="${PULP_PATH}/process/${PROCESS}"
if ( ! -d "${PROCESS_DIR}" ) then
  if ( $?ICB_PATH && "$ICB_PATH" != "" ) then
    set PROCESS_DIR="${ICB_PATH}/process/${PROCESS}"
  endif
endif

# For tcsh, it looks there is no way to get source path of a script 
# that is sourced by a source script.
# Reference:
#   https://serverfault.com/a/139302/444463
#   https://serverfault.com/a/139313/444463
#   https://unix.stackexchange.com/a/4658
#
# E.g. a.csh is executed (not sourced)
#      a.csh source b.csh
#      b.csh sources c.sh
#
#      b.csh can use $_ to get sourced script name
#      But $_ evaled from c.csh is b.csh
# A workaround is required.
set SOURCED="${PROCESS_DIR}/vcompile.csh"
source "$SOURCED"

# chip-top
echo "Compiling Process Specific Chip Top ..."
set PROCESS_CHIP_TOP_DIR="${RTL_PATH}/chip_top"
if ( $?ICB_PATH && "$ICB_PATH" != "" && -d "${ICB_PATH}/rtl/chip_top/${PROCESS}" ) then
  # Use common chip top
  set PROCESS_CHIP_TOP_DIR="${ICB_PATH}/rtl/chip_top/${PROCESS}"
endif
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${PROCESS_CHIP_TOP_DIR}/pulpino_top_wrapper.sv   || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${PROCESS_CHIP_TOP_DIR}/pulpino_pads.sv          || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${PROCESS_CHIP_TOP_DIR}/pulpino_top_with_pads.sv || goto error


#
# Process dependent files
#
echo "Compiling Process Specific Components ..."
# C shell does not support function
set PROCESS_COMP_DIR="${RTL_PATH}/components/${PROCESS}"
if ( ! -d "${PROCESS_COMP_DIR}" ) then
  if ( $?ICB_PATH && "$ICB_PATH" != "" ) then
    set PROCESS_COMP_DIR="${ICB_PATH}/rtl/components/${PROCESS}"
  endif
endif

# To allow space in the path,
# replace space to \1, \0 to space for list construction.
foreach each ( `find "${PROCESS_COMP_DIR}" -name '*.sv' -print0 | sort -z | tr ' ' '\1' | tr '\0' ' '` )
  # Convert '\1' back to space
  set sv_file=`echo -n "$each" | tr '\1' ' '`
  echo Find "$sv_file" and compiling ...

  vlog -quiet -sv -work ${LIB_PATH} "$sv_file"  || goto error
end

vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/generic_fifo.sv            || goto error
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/rstgen.sv                  || goto error
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/sp_ram_banked.sv           || goto error

# files depending on RISCV vs. OR1K
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/core_region.sv             || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/random_stalls.sv           || goto error

vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/boot_rom_wrap.sv           || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/boot_code.sv               || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/sp_ram_wrap.sv             || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/instr_ram_wrap.sv          || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/ram_mux.sv                 || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/axi_node_intf_wrap.sv      || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/pulpino_top.sv             || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/peripherals.sv             || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/periph_bus_wrap.sv         || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/axi2apb_wrap.sv            || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/axi_spi_slave_wrap.sv      || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/axi_mem_if_SP_wrap.sv      || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/clk_rst_gen.sv             || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/axi_slice_wrap.sv          || goto error
vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/core2axi_wrap.sv           || goto error

#
# User Pulgin
#
echo "Compiling User Plugin ..."

# To allow space in the path,
# replace space to \1, \0 to space for list construction.

# Compile RTL
foreach each ( `find "${RTL_PATH}/user_plugin/rtl/" \( -name '*.sv' -o -name '*.v' \) -print0 | sort -z | tr ' ' '\1' | tr '\0' ' '` )
  # Convert '\1' back to space
  set rtl_file=`echo -n "$each" | tr '\1' ' '`
  echo Find "$rtl_file" and compiling ...

  set sv_opt=""
  switch ("$rtl_file")
    case *.sv:
      set sv_opt="-sv"
      breaksw
  endsw

  vlog -quiet $sv_opt -work ${LIB_PATH} +incdir+"${RTL_PATH}/user_plugin/rtl/" +incdir+"${RTL_PATH}/includes" ${ASIC_DEFINES} ${CORE_DEFINES} "$rtl_file"  || goto error
end


echo "${Cyan}--> ${IP_NAME} compilation complete! ${NC}"
exit 0

##############################################################################
# Error handler
##############################################################################

error:
echo "${NC}"
exit 1
