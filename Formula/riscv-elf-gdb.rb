require "formula"

class RiscvElfGdb < Formula
  homepage "https://www.gnu.org/software/binutils/"
  desc "GNU debugger for bare metal RISC-V targets"
  url "https://sourceware.org/pub/gdb/releases/gdb-15.1.tar.xz"
  sha256 "38254eacd4572134bca9c5a5aa4d4ca564cbbd30c369d881f733fb6b903354f2"

  depends_on "gmp"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "readline"
  depends_on "expat"
  depends_on "python"
  depends_on "texinfo" => :build
  depends_on "flex" => :build
  depends_on "bison" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  # Linux dependencies.
  depends_on "guile" unless OS.mac?

  def install
    mkdir "build" do
      system "../configure",
             "--prefix=#{prefix}",
             "--target=riscv64-unknown-elf",
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
