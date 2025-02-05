require "formula"

class RiscvElfBinutils < Formula
  homepage "https://www.gnu.org/software/binutils/"
  desc "GNU Binutils for bare metal RISC-V targets"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.zst"
  sha256 "79cb120b39a195ad588cd354aed886249bfab36c808e746b30208d15271cc95c"

  depends_on "gmp"
  depends_on "mpfr"
  depends_on "texinfo" => :build
  depends_on "flex" => :build
  depends_on "bison" => :build

  def install
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
