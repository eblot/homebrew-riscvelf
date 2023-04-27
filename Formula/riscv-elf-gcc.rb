require "formula"

class RiscvElfGcc < Formula
  desc "GNU C/C++ compiler for baremetal RISC-V targets"
  homepage "https://gcc.gnu.org"
  url 'http://ftpmirror.gnu.org/gcc/gcc-13.1.0/gcc-13.1.0.tar.xz'
  sha256 '61d684f0aa5e76ac6585ad8898a2427aade8979ed5e7f85492286c4dfc13ee86'

  depends_on "riscv-elf-binutils"
  depends_on "gmp"
  depends_on "isl"
  depends_on "libelf"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "python"

  keg_only "conflict with other GCC installations"

  resource "newlib" do
    url "ftp://sourceware.org/pub/newlib/newlib-4.2.0.20211231.tar.gz"
    sha256 "c3a0e8b63bc3bef1aeee4ca3906b53b3b86c8d139867607369cb2915ffc54435"
  end

  patch :DATA

  def install
    coredir = Dir.pwd

    resource("newlib").stage do
      cp_r Dir.pwd+"/newlib", coredir+"/newlib"
    end

    gmp = Formulary.factory "gmp"
    mpfr = Formulary.factory "mpfr"
    libmpc = Formulary.factory "libmpc"
    libelf = Formulary.factory "libelf"
    isl = Formulary.factory "isl"
    binutils = Formulary.factory "riscv-elf-binutils"

    # Fix up CFLAGS for cross compilation (default switches cause build issues)
    ENV["CFLAGS_FOR_BUILD"] = "-O2"
    ENV["CFLAGS"] = "-O2"
    ENV["CFLAGS_FOR_TARGET"] = "-Os -mcmodel=medany"
    ENV["CXXFLAGS_FOR_BUILD"] = "-O2"
    ENV["CXXFLAGS"] = "-O2"
    ENV["CXXFLAGS_FOR_TARGET"] = "-Os -mcmodel=medany"

    build_dir="build"
    mkdir build_dir
    Dir.chdir build_dir do
      system "sh #{coredir}/mlgen.sh"
      multilib_list = File.read("multilib_list").strip
      system coredir+"/configure",
          "--target=riscv64-unknown-elf",
          "--prefix=#{prefix}",
          "--disable-shared",
          "--disable-threads",
          "--enable-languages=c,c++",
          "--with-system-zlib",
          "--enable-tls",
          "--enable-checking=yes",
          "--with-newlib",
          "--with-sysroot=#{prefix}/riscv64-unknown-elf",
          "--enable-lto",
          "--disable-libmudflap",
          "--disable-libssp",
          "--disable-libquadmath",
          "--disable-libgomp",
          "--disable-nls",
          "--disable-tm-clone-registry",
          "--with-python=/usr/bin/python3",
          "--with-gnu-as",
          "--with-gnu-ld",
          "--with-gmp=#{gmp.opt_prefix}",
          "--with-mpfr=#{mpfr.opt_prefix}",
          "--with-mpc=#{libmpc.opt_prefix}",
          "--with-isl=#{isl.opt_prefix}",
          "--with-libelf=#{libelf.opt_prefix}",
          "--with-riscv-attribute=yes",
          "--enable-multilib",
          "--with-multilib-generator=#{multilib_list}",
          "--enable-checking=release",
          "--disable-debug",
          "--with-abi=lp64d",
          "--with-arch=rv64imafdc_zicsr_zifencei",
          "--with-isa-spec=20191213"
      system "make"
      system "make -j1 -k install"

      system "ln -s #{binutils.prefix}/riscv64-unknown-elf/bin #{prefix}/riscv64-unknown-elf/bin"
    end
  end
end

__END__
diff --git a/mlgen.sh b/mlgen.sh
new file mode 100755
index 0000000..fc780ea
--- /dev/null
+++ b/mlgen.sh
@@ -0,0 +1,19 @@
+#!/bin/sh
+
+#MULTILIB_RV32E="rv32eac-ilp32e--;rv32ec-ilp32e--;rv32emac-ilp32e--"
+MULTILIB_RV32="rv32imc-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--"
+#MULTILIB_RV64="rv64iac-lp64--;rv64ic-lp64--;rv64imc-lp64--;rv64imac-lp64--;rv64imafc-lp64f--;rv64imfc-lp64f--;rv64imafdc-lp64d--"
+MULTILIB_LIST="${MULTILIB_RV32E};${MULTILIB_RV32};${MULTILIB_RV64}"
+
+# create list of architectures to support
+multilib_list=""
+for lib in $(echo $MULTILIB_LIST | tr ';' [:space:]); do
+    lhead=$(echo $lib | cut -d- -f1)
+    ltail=$(echo $lib | sed -r "s/${lhead}\-//")
+    zlib=$(echo "${lhead}_zba_zbb-${ltail}")
+    multilib_list="${multilib_list};${lib};${zlib}"
+done
+#multilib_list="${multilib_list};--cmodel=compact"
+echo ${multilib_list} | cut -c2- > multilib_list
+cat multilib_list
+
