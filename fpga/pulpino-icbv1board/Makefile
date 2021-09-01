include fpga-settings.mk

.PHONY: all
all: ips pulpino
#pulpemu sw is temp delete


.PHONY: ips
ips: clk mem fp_fma


.PHONY: clk
clk: ips/xilinx_clock_manager/ip/xilinx_clock_manager.dcp

ips/xilinx_clock_manager/ip/xilinx_clock_manager.dcp:
	@echo "\nstart icbv1board\n"
	make -C ips/xilinx_clock_manager/ clean all

.PHONY: mem
mem: ips/xilinx_mem_8192x32/ip/xilinx_mem_8192x32.dcp

ips/xilinx_mem_8192x32/ip/xilinx_mem_8192x32.dcp:
	make -C ips/xilinx_mem_8192x32/ clean all


.PHONY: mem_dp
mem_dp: ips/xilinx_mem_32768x32_dp/ip/xilinx_mem_32768x32_dp.dcp

ips/xilinx_mem_32768x32_dp/ip/xilinx_mem_32768x32_dp.dcp:
	make -C ips/xilinx_mem_32768x32_dp/ clean all

.PHONY: fp_fma
fp_fma: ips/xilinx_fp_fma/ip/xilinx_fp_fma.dcp

ips/xilinx_fp_fma/ip/xilinx_fp_fma.dcp:
	make -C ips/xilinx_fp_fma/ clean all

.PHONY: pulpino
pulpino: pulpino/pulpino.edf

pulpino/pulpino.edf:
	make -C pulpino clean all




.PHONY: clean
clean:
	make -C ips/xilinx_clock_manager/ clean
	make -C ips/xilinx_mem_8192x32/ clean
	make -C ips/xilinx_mem_32768x32_dp/ clean
	make -C ips/xilinx_fp_fma/ clean
	make -C pulpino clean