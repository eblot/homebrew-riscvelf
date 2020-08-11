require "formula"

class RiscvElfBinutils < Formula
  desc "GNU Binutils for OS-less RISC-V architecture"
  homepage "https://www.gnu.org/software/binutils/"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz"
  sha256 "1b11659fb49e20e18db460d44485f09442c8c56d5df165de9461eb09c8302f85"

  depends_on "gmp"
  depends_on "mpfr"

  def install
    system "./configure", "--prefix=#{prefix}", "--target=riscv64-unknown-elf",
                "--disable-shared", "--disable-nls",
                "--with-gmp=#{Formulary.factory("gmp").prefix}",
                "--with-mpfr=#{Formulary.factory("mpfr").prefix}",
                "--disable-cloog-version-check",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end
