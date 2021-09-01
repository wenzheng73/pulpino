# Run Simulations

The software is built using CMake.


## Prepare Build Directory

Create a `build` directory somewhere, e.g. in the `pulpino` directory

```sh
cd pulpino
mkdir build
```

Link the `sw/cmake_configure.gcc.sh` in the build directory.

```sh
cd build
ln -s ../sw/cmake_configure.gcc.sh .
```

## Setup Environment

To let the configure script find tools

1. Setup PATH for simulator (ModelSim)
1. Setup PATH for ETH GNU toolchain<br>
   [Get the ETH GNU toolchain](https://github.com/icb-platform/ri5cy_gnu_toolchain/releases)


## Configure

Modify the `cmake_configure.gcc.sh` to your needs and execute it inside the build directory.
This will setup everything to perform simulations using ModelSim.

`cmake_configure.gcc.sh` options

1. `--core` option

   1. `ri5cy`

      It automatically selects the RISCY cores and compiles SW with all the PULP-extensions and the RV32IM support.
      The GCC ETH compiler is needed and the GCC march flag set to "IMXpulpv2".
      
   1. `ri5cyfpu`

      It automatically selects the RISCY cores and compiles SW with all the PULP-extensions and the RV32IMF support.
      The GCC ETH compiler is needed and he GCC march flag set to "IMFXpulpv2".

   1. `zeroriscy`

      It automatically selects the zero-riscy cores and compiles SW with the RV32IM support (march flag set to RV32IM).

1. `--memload` option

   1. `PRELOAD`

      Let testbench load firmware to sram by writing to sram model directly. This is pure functional behavior.

   1. `SPI`

      Let testbench load firmware to sram through SPI slave.

   1. `STANDALONE`

      Let testbench boot PULPino from boot ROM, and the boot ROM loads firmware from the external flash.<br>
      To use the external flash in testbench:
      1. [Prepare flash vip](vip/spi_flash/README.md)
      1. Set parameter `USE_W25Q16JV_MODEL` to 1 in [tb/tb_chip_top.sv](tb/tb_chip_top.sv)

Activate the RVC flag in the cmake file if compressed instructions are desired.

E.g. To use `zeroriscy` cpu core, and let testbentch load firmware through SPI slave.
Inside the `build` directory, execute

```sh
./cmake_configure.gcc.sh --core zeroriscy --memload SPI
```


## Compile RTL

Inside the build directory, execute

```sh
make vcompile
```

to compile the RTL libraries using ModelSim.


## Run a Single Test

To run a simulation in the modelsim GUI use

```sh
make helloworld.vsim
```

To run a simulation in the modelsim console use

```sh
make helloworld.vsimc
```

This will output a summary at the end of the simulation.
This is intended for batch processing of a large number of tests.

Replace helloworld with the test/application you want to run.


## Run Tests in Parallel

Before running all tests, all firmwares should be built

```sh
make all
```

To run all tests in parallel, execute

```sh
ctest --timeout 3600 -LE 'fpga' -E '(testUART|testSPIMaster|boot_code|freertos)' -j 20
```

The above command exclude some tests which are never finish or always fail.


## Using ninja instead of make

You can use ninja instead make to build software for PULPino, just replace all
occurrences of make with ninja.
The same targets are supported on both make and ninja.
