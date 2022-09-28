require "formula"

class RiscvElfGdb < Formula
  homepage "https://www.gnu.org/software/binutils/"
  desc "GNU debugger for bare metal RISC-V targets"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.39.tar.xz"
  sha256 "645c25f563b8adc0a81dbd6a41cffbf4d37083a382e02d5d3df4f65c09516d00"

  depends_on "gmp"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "readline"
  depends_on "expat"
  depends_on "python"
  depends_on "texinfo" => :build
  depends_on "flex" => :build
  depends_on "bison" => :build
  depends_on "bison" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  # Linux dependencies.
  depends_on "guile" unless OS.mac?

  # need to regenerate configure script after applying patch
  if OS.mac?
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    mkdir "build" do
      system "../configure",
             "--prefix=#{prefix}",
             "--target=riscv64-unknown-elf",
             "--disable-shared",
             "--disable-nls",
             "--with-gmp=#{Formulary.factory("gmp").prefix}",
             "--with-mpfr=#{Formulary.factory("mpfr").prefix}",
             "--with-mpc=#{Formulary.factory("libmpc").prefix}",
             "--with-readline=#{Formulary.factory("readline").prefix}",
             "--with-python3=#{Formulary.factory("python").prefix}/bin/python3",
             "--with-expat=#{Formulary.factory("expat").prefix}",
             "--without-cloog",
             "--enable-multilibs",
             "--enable-lto",
             "--enable-gdb",
             "--disable-binutils",
             "--disable-ld",
             "--disable-gold",
             "--disable-gas",
             "--disable-sim",
             "--disable-gprof",
             "--disable-werror",
             "--disable-debug",
             "--disable-ld",
             "--disable-gold",
             "--disable-gas",
             "--disable-sim",
             "--disable-gprof",
             "--disable-gold"
      system "make"
      system "make install"
      system "(cd #{prefix}/share/info && \
               for info in *.info; do \
                  mv $info $(echo $info | sed 's/^/riscv64-unknown-elf-/'); done)"
    end
  end
end
