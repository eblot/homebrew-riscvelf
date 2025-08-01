require "formula"

class RiscvElfBinutils < Formula
  homepage "https://www.gnu.org/software/binutils/"
  desc "GNU Binutils for bare metal RISC-V targets"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.45.tar.zst"
  sha256 "7f288c9a869582d53dc645bf1b9e90cc5123f6862738850472ddbca69def47a3"

  depends_on "gmp"
  depends_on "mpfr"
  depends_on "texinfo" => :build
  depends_on "flex" => :build
  depends_on "bison" => :build

  def install
    # workaround for old zlib own workaround for MacOS
    # zlib considers that fdopen does not exist on MacOS, which no longer stands true.
    ENV.append "CFLAGS", "-Dfdopen=fdopen"
    mkdir "build" do
      system "../configure",
             "--prefix=#{prefix}",
             "--target=riscv64-unknown-elf",
             "--disable-shared",
             "--disable-nls",
             "--with-gmp=#{Formulary.factory("gmp").prefix}",
             "--with-mpfr=#{Formulary.factory("mpfr").prefix}",
             "--disable-cloog-version-check",
             "--enable-multilib",
             "--enable-lto",
             "--disable-werror",
             "--disable-debug",
             "--disable-gdb",
             "--disable-gold",
             "--disable-sim"
      system "make"
      system "make install"
      system "rm #{prefix}/lib/bfd-plugins/libdep.a"
      system "(cd #{prefix}/share/info && \
               for info in *.info; do \
                  mv $info $(echo $info | sed 's/^/riscv64-unknown-elf-/'); done)"
    end
  end
end
