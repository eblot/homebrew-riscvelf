require "formula"

class RiscvElfGdb < Formula
  desc "GNU debugger for RISC-V architecture"
  homepage "https://www.gnu.org/software/gdb/"
  url "https://ftp.gnu.org/gnu/gdb/gdb-9.2.tar.xz"
  sha256 "360cd7ae79b776988e89d8f9a01c985d0b1fa21c767a4295e5f88cb49175c555"

  depends_on "gmp"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "readline"

  # Linux dependencies.
  depends_on "python" unless OS.mac?
  depends_on "guile" unless OS.mac?

  def install
    mkdir "build" do
      system "../configure", "--prefix=#{prefix}",
                "--target=riscv64-unknown-elf",
                "--with-gmp=#{Formulary.factory("gmp").prefix}",
                "--with-mpfr=#{Formulary.factory("mpfr").prefix}",
                "--with-mpc=#{Formulary.factory("libmpc").prefix}",
                "--with-readline=#{Formulary.factory("readline").prefix}",
                "--with-python",
                "--without-cloog",
                "--enable-lto", "--disable-werror"
      system "false"
      system "make"
      system "make install"
    end
  end
end
