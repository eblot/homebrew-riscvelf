require "formula"

class RiscvElfBinutils < Formula
  homepage "https://www.gnu.org/software/binutils/"
  desc "GNU Binutils for bare metal RISC-V targets"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz"
  sha256 "0f8a4c272d7f17f369ded10a4aca28b8e304828e95526da482b0ccc4dfc9d8e1"

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
             "--disable-sim",
             "--with-isa-spec=20191213"
      system "make"
      system "make install"
      system "rm #{prefix}/lib/bfd-plugins/libdep.a"
      system "(cd #{prefix}/share/info && \
               for info in *.info; do \
                  mv $info $(echo $info | sed 's/^/riscv64-unknown-elf-/'); done)"
    end
  end
end
