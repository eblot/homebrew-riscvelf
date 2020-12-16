require "formula"

class Riscv64Newlib < Formula
  desc "C libraries for baremetal RISC-V 64-bit targets"
  homepage "https://llvm.org/"
  # and "https://sourceware.org/newlib/"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/llvm-project-11.0.0.tar.xz"
    sha256 "b7b639fc675fa1c86dd6d0bc32267be9eb34451748d2efd03f674b773000e92b"

    resource "newlib" do
      url "ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz"
      sha256 "58dd9e3eaedf519360d92d84205c3deef0b3fc286685d1c562e245914ef72c66"
    end
  end

  keg_only "conflict with llvm"

  depends_on "riscv-elf-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python" => :build

  def install
    llvm = Formulary.factory "riscv-elf-llvm"

    xtarget = "riscv64-unknown-elf"
    xmodel = "-mcmodel=medany"

    xopts = "-g -Os"
    xcfeatures = "-ffunction-sections -fdata-sections -fno-stack-protector -fvisibility=hidden"
    xcxxfeatures = "#{xcfeatures} -fno-use-cxa-atexit"

    xcxxdefs = "-D_LIBUNWIND_IS_BAREMETAL=1 -D_GNU_SOURCE=1 -D_POSIX_TIMERS=1"
    xcxxdefs = "#{xcxxdefs} -D_LIBCPP_HAS_NO_LIBRARY_ALIGNED_ALLOCATION"
    xcxxnothread = "-D_LIBCPP_HAS_NO_THREADS=1"

    (buildpath/"newlib").install resource("newlib")

    ENV.append_path "PATH", "#{llvm.bin}"

    ENV["CC_FOR_TARGET"] = "#{llvm.bin}/clang"
    ENV["AR_FOR_TARGET"] = "#{llvm.bin}/llvm-ar"
    ENV["NM_FOR_TARGET"] = "#{llvm.bin}/llvm-nm"
    ENV["RANLIB_FOR_TARGET"] = "#{llvm.bin}/llvm-ranlib"
    ENV["READELF_FOR_TARGET"] = "#{llvm.bin}/llvm-readelf"
    ENV["AS_FOR_TARGET"] = "#{llvm.bin}/clang"

    host=`cc -dumpmachine`.strip

    # Note: beware that enable assertions disables CMake's NDEBUG flag, which
    # in turn enable calls to fprintf/fflush and other stdio API, which may
    # add up 40KB to the final executable...

    ["i", "ia", "iac", "im", "imac", "iaf", "iafd", "imf", "imfd",
     "imafc", "imafdc"].each do |abi|
      if abi.include? "d"
          fp="d"
      elsif abi.include? "f"
          fp="f"
      else
          fp=""
      end
      xarch = "rv64#{abi}"
      xctarget = "-march=#{xarch} -mabi=lp64#{fp} #{xmodel}"
      xarchdir = "#{xarch}"
      xsysroot = "#{prefix}/#{xtarget}/#{xarchdir}"
      xcxx_inc = "-I#{xsysroot}/include"
      xcxx_lib = "-L#{xsysroot}/lib"
      xcflags = "#{xctarget} #{xopts} #{xcfeatures}"
      # remap source file path so that it is possible to step-debug system
      # library files (see below)
      xncflags = "#{xcflags} -fdebug-prefix-map=#{buildpath}/newlib=#{opt_prefix}/#{xtarget}"
      ENV["CFLAGS_FOR_TARGET"] = "-target #{xtarget} #{xncflags} -Wno-unused-command-line-argument"

      mktemp do
        puts "--- newlib #{xarch} ---"
        system "#{buildpath}/newlib/configure",
                  "--host=#{host}",
                  "--build=#{host}",
                  "--target=#{xtarget}",
                  "--prefix=#{xsysroot}",
                  "--disable-newlib-supplied-syscalls",
                  "--enable-newlib-reent-small",
                  "--disable-newlib-fvwrite-in-streamio",
                  "--disable-newlib-fseek-optimization",
                  "--disable-newlib-wide-orient",
                  "--enable-newlib-nano-malloc",
                  "--disable-newlib-unbuf-stream-opt",
                  "--enable-lite-exit",
                  "--enable-newlib-global-atexit",
                  "--disable-newlib-nano-formatted-io",
                  "--disable-newlib-fvwrite-in-streamio",
                  "--enable-newlib-io-c99-formats",
                  "--enable-newlib-io-float",
                  "--disable-newlib-io-long-double",
                  "--disable-nls"
        system "make"
        # deparallelise (-j1) is required or installer fails to create output dir
        system "make -j1 install; true"
        system "mv #{xsysroot}/#{xtarget}/* #{xsysroot}/"
        system "rm -rf #{xsysroot}/#{xtarget}"
      end
      # newlib

      xccflags = "#{xcflags} -fdebug-prefix-map=#{buildpath}/compiler-rt=#{opt_prefix}/#{xtarget}/compiler-rt"

      mktemp do
        puts "--- compiler-rt #{xarch} ---"
        system "cmake",
                  "-G", "Ninja",
                  *std_cmake_args,
                  "-DCMAKE_INSTALL_PREFIX=#{xsysroot}",
                  "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
                  "-DCMAKE_SYSTEM_PROCESSOR=arm",
                  "-DCMAKE_SYSTEM_NAME=Generic",
                  "-DCMAKE_CROSSCOMPILING=ON",
                  "-DCMAKE_CXX_COMPILER_FORCED=TRUE",
                  "-DCMAKE_BUILD_TYPE=Release",
                  "-DCMAKE_C_COMPILER=#{llvm.bin}/clang",
                  "-DCMAKE_CXX_COMPILER=#{llvm.bin}/clang++",
                  "-DCMAKE_LINKER=#{llvm.bin}/clang",
                  "-DCMAKE_AR=#{llvm.bin}/llvm-ar",
                  "-DCMAKE_RANLIB=#{llvm.bin}/llvm-ranlib",
                  "-DCMAKE_C_COMPILER_TARGET=#{xtarget}",
                  "-DCMAKE_ASM_COMPILER_TARGET=#{xtarget}",
                  "-DCMAKE_SYSROOT=#{xsysroot}",
                  "-DCMAKE_SYSROOT_LINK=#{xsysroot}",
                  "-DCMAKE_C_FLAGS=#{xccflags}",
                  "-DCMAKE_ASM_FLAGS=#{xccflags}",
                  "-DCMAKE_CXX_FLAGS=#{xccflags}",
                  "-DCMAKE_EXE_LINKER_FLAGS=-L#{xsysroot}/lib",
                  "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                  "-DLLVM_DEFAULT_TARGET_TRIPLE=#{xtarget}",
                  "-DLLVM_TARGETS_TO_BUILD=ARM",
                  "-DLLVM_ENABLE_PIC=OFF",
                  "-DCOMPILER_RT_OS_DIR=baremetal",
                  "-DCOMPILER_RT_BUILD_BUILTINS=ON",
                  "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
                  "-DCOMPILER_RT_BUILD_XRAY=OFF",
                  "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
                  "-DCOMPILER_RT_BUILD_PROFILE=OFF",
                  "-DCOMPILER_RT_BAREMETAL_BUILD=ON",
                  "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON",
                  "-DCOMPILER_RT_INCLUDE_TESTS=OFF",
                  "-DCOMPILER_RT_USE_LIBCXX=ON",
                  "-DUNIX=1",
                  "#{buildpath}/compiler-rt"
        system "ninja"
        system "ninja install"
        system "mv #{xsysroot}/lib/baremetal/* #{xsysroot}/lib"
        system "rmdir #{xsysroot}/lib/baremetal"
      end
      # compiler-rt

      # extract the list of actually used source files, so they can be copied
      # into the destination tree (so that it is possible to step-debug in
      # the system libraries)
      system "llvm-dwarfdump #{xsysroot}/lib/*.a | grep DW_AT_decl_file | \
        tr -d ' ' | cut -d'\"' -f2 >> #{buildpath}/srcfiles.tmp"

    end
    # for arch

    # find unique source files, would likely be easier in Ruby,
    # but Ruby is dead - or should be :-)
    # newlib/ files and compiler-rt are handled one after another, as newlib
    # as an additional directory level
    # realpath is required to resolve ../ path specifier, which are otherwise
    # trash by tar, leading to invalid path (maybe cpio would be better here?)
    puts "--- library source files ---"
    system "sort -u #{buildpath}/srcfiles.tmp | grep -E '/(newlib|libgloss)/' | \
      sed 's%^#{opt_prefix}/#{xtarget}/%%' | grep -v '^/' | \
      (cd newlib; xargs -n 1 realpath --relative-to .) \
        > #{buildpath}/newlib.files"
    system "cat #{buildpath}/newlib.files"
    system "sort -u #{buildpath}/srcfiles.tmp | grep -E '/compiler-rt/' |
      sed 's%^#{opt_prefix}/#{xtarget}/%%' | grep -v '^/' \
        > #{buildpath}/compiler-rt.files"
    system "rm #{buildpath}/srcfiles.tmp"
    system "tar cf - -C #{buildpath}/newlib -T #{buildpath}/newlib.files | \
      tar xf - -C #{prefix}/#{xtarget}"
    system "tar cf - -C #{buildpath} -T #{buildpath}/compiler-rt.files | \
      tar xf - -C #{prefix}/#{xtarget}"
  end
  # install
end
# formula
