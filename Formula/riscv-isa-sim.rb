class RiscvIsaSim < Formula
  desc "Spike RISC-V ISA Simulator"
  homepage "https://github.com/riscv/riscv-isa-sim"
  license "BSD 3-clause"
  head "https://github.com/riscv/riscv-isa-sim.git"
  # do not use this fully outdated version, use HEAD
  url "https://github.com/riscv/riscv-isa-sim/archive/v1.0.0.tar.gz"
  sha256 "7ad7f2bac701ab01a469a7ed07075ae1509e3a617da107ef364eebf21d3324a8"

  depends_on "dtc"

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make"
    system "make -j1 install"
  end
end
