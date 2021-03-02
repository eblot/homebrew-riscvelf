require "formula"

class RiscvElfBinutils < Formula
  desc "GNU Binutils for OS-less RISC-V architecture"
  homepage "https://www.gnu.org/software/binutils/"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.36.1.tar.xz"
  sha256 "e81d9edf373f193af428a0f256674aea62a9d74dfe93f65192d4eae030b0f3b0"

  depends_on "gmp"
  depends_on "mpfr"

  def install
    mkdir "build" do
      system "../configure", "--prefix=#{prefix}", "--target=riscv64-unknown-elf",
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
end
