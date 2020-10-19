require "formula"

class RiscvElfBinutils < Formula
  desc "GNU Binutils for OS-less RISC-V architecture"
  homepage "https://www.gnu.org/software/binutils/"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.35.1.tar.xz"
  sha256 "3ced91db9bf01182b7e420eab68039f2083aed0a214c0424e257eae3ddee8607"

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
