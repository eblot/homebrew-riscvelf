# Homebrew formulae for RISC-V baremetal toolchains on macOS

## How do I install these formulae?

* GNU binutils are used with GCC toolchain and as the linker with the LLVM toolchain,
  as LLVM linker does not yet support relaxation: `brew install riscv-elf-binutils`
* LLVM/clang toolchain `brew install rriscv-elf-llvm`
* Clang C runtime `brew install rriscv-elf-compiler-rt`
* C libraries for Clang `brew install rriscv-elf-newlib`
* GCC toolchain (w/ C runtime and C libraries) `brew install rriscv-elf-gcc`
* OpenOCD for JTAG communication `brew install riscv-openocd`
* Not yet supported: GDB ~~brew install rriscv-elf-gdb~~

## Additional packages

* FPGA bitstream flasher `brew install openfpgaloader`

