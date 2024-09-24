require "formula"

class RiscvElfCompilerRt < Formula
  desc "Compiler runtime for baremetal RISC-V targets"
  homepage "https://compiler-rt.llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.0/llvm-project-19.1.0.src.tar.xz"
  sha256 "5042522b49945bc560ff9206f25fb87980a9b89b914193ca00d961511ff0673c"

  patch :DATA

  option "with-debug", "Build libraries in debug mode"
  option "with-nano", "Build libraries in in nano mode"

  depends_on "riscv-elf-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python" => :build
  depends_on "coreutils" => :build if OS.mac?

  # note: linuxbrew is not supported

  def install
    llvm = Formulary.factory "riscv-elf-llvm"

    ENV.append_path "PATH", "#{llvm.bin}"

    host=`cc -dumpmachine`.strip

    if build.with? "debug"
      xopts = "-g -Og"
    else
      xopts="-Os"
    end

    clang_version=`#{llvm.bin}/clang --version 2>&1 | head -1`.strip
    clang_version = clang_version.gsub(/^.* ([\.0-9]+)$/, '\1')
    xcfeatures = "-ffunction-sections -fdata-sections -fno-stack-protector -fvisibility=hidden"

    # Note: beware that enable assertions disables CMake's NDEBUG flag, which
    # in turn enable calls to fprintf/fflush and other stdio API, which may
    # add up 40KB to the final executable...

    xlens = [32, 64]
    compacts = [""]
    abis = ["ic", "iac", "imc", "imac", "imafc", "imafdc"]
    dabis = []
    abis.each do |abi|
      dabis.push(abi)
    end
    xabis = []
    dabis.each do |abi|
      xabis.push(abi)
      xabis.push("#{abi}_zba1p0_zbb1p0")
    end
    xlens.each do |xlen|
      compacts.each do |compact|
        if xlen == 32 and compact != ""
          next
        end
        xabis.each do |abi|
          if abi.include? "d"
            xabix="d"
          elsif abi.include? "f"
            xabix="f"
          else
            xabix=""
          end

          if xlen == 64
              xabi="lp"
              if compact == ""
                xmodel="-mcmodel=medany"
              else
                xmodel="-mcmodel=compact"
              end
          elsif xlen == 32
              xabi="ilp"
              xmodel="-mcmodel=medlow"
          end

          labi = xabi.split('_')[0]
          if labi.include?('a')
              xatomics="OFF"
          else
              xatomics="ON"
          end

          xtarget = "riscv#{xlen}-unknown-elf"
          xarch = "rv#{xlen}#{abi}"
          xctarget = "-march=#{xarch} -mabi=#{xabi}#{xlen}#{xabix} #{xmodel}"
          xarchdir = xarch.gsub(/[0-9]+p[0-9]+/, '')
          xsysroot = "#{prefix}/lib/clang/riscv64-unknown-elf/#{clang_version}/#{xarchdir}/#{xabi}#{xlen}#{xabix}#{compact}"
          xcflags = "#{xctarget} #{xopts} #{xcfeatures}"

          if xarch.match(/[0-1]+p[0-9]+/)
            xcflags = "#{xcflags} -menable-experimental-extensions"
          end
          # remap source file path so that it is possible to step-debug system
          # library files (see below)
          xncflags = "#{xcflags} -fdebug-prefix-map=#{buildpath}=#{prefix}/src"

          ENV["CFLAGS_FOR_TARGET"] = "-target #{xtarget} #{xncflags} -Wno-unused-command-line-argument"

          if OS.mac?
            # no idea why cmake uses /tmp which is a symlink to /private/tmp
            # even if it is run from /private/tmp. This is hackish, looking for a
            # better way
            vbuildpath = buildpath.sub(/^\/private\/tmp\//, "/tmp/")
          else
            vbuildpath = buildpath
          end
          xcrtflags = "#{xcflags} -fdebug-prefix-map=#{vbuildpath}/compiler-rt/lib=#{prefix}/lib/clang/#{clang_version}/src/compiler-rt"

          mktemp do
            puts "--- compiler-rt #{xarch}/#{xabi}#{xlen}#{xabix}#{compact} ---"
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
                      "-DCMAKE_C_FLAGS=#{xcrtflags}",
                      "-DCMAKE_ASM_FLAGS=#{xcrtflags}",
                      "-DCMAKE_CXX_FLAGS=#{xcrtflags}",
                      "-DCMAKE_EXE_LINKER_FLAGS=-L#{xsysroot}/lib",
                      "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                      "-DLLVM_DEFAULT_TARGET_TRIPLE=#{xtarget}",
                      "-DLLVM_TARGETS_TO_BUILD=RISCV",
                      "-DLLVM_ENABLE_PIC=OFF",
                      "-DCOMPILER_RT_OS_DIR=baremetal",
                      "-DCOMPILER_RT_BUILD_BUILTINS=ON",
                      "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
                      "-DCOMPILER_RT_BUILD_XRAY=OFF",
                      "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
                      "-DCOMPILER_RT_BUILD_PROFILE=OFF",
                      "-DCOMPILER_RT_BAREMETAL_BUILD=ON",
                      "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON",
                      "-DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=#{xatomics}",
                      "-DCOMPILER_RT_INCLUDE_TESTS=OFF",
                      "-DCOMPILER_RT_USE_LIBCXX=ON",
                      "-DUNIX=1",
                      "#{buildpath}/compiler-rt"
            system "ninja"
            system "ninja install"
            system "mv #{xsysroot}/lib/baremetal/* #{xsysroot}/"
            system "rm -rf #{xsysroot}/lib"
          end
          # compiler-rt

          if build.with? "debug"
            # extract the list of actually used source files, so they can be copied
            # into the destination tree (so that it is possible to step-debug in
            # the system libraries)
            system "llvm-dwarfdump #{xsysroot}/*.a | \
              grep DW_AT_decl_file | tr -d ' ' | cut -d'\"' -f2 \
              >> #{buildpath}/srcfiles.tmp"
          end
        end
        # for isa
      end
      # for compact
    end
    # fior xlen

    if build.with? "debug"
      # find unique source files, would likely be easier in Ruby,
      # but Ruby is dead - or should be :-)
      # newlib/ files and compiler-rt are handled one after another, as newlib
      # as an additional directory level
      # realpath is required to resolve ../ path specifier, which are otherwise
      # trash by tar, leading to invalid path (maybe cpio would be better here?)
      puts "--- library source files ---"
      system "sort -u #{buildpath}/srcfiles.tmp"
      system "sort -u #{buildpath}/srcfiles.tmp | grep -E '/(compiler-rt)/'"
      system "sort -u #{buildpath}/srcfiles.tmp | grep -E '/(compiler-rt)/' | \
        sed 's%^#{prefix}/lib/clang/#{clang_version}/src/compiler-rt/%%'"
      system "sort -u #{buildpath}/srcfiles.tmp | grep -E '/(compiler-rt)/' | \
        sed 's%^#{prefix}/lib/clang/#{clang_version}/src/compiler-rt/%%' | \
          grep -v '^/' | > #{buildpath}/srcfiles.files"
      system "cat #{buildpath}/srcfiles.files"
      system "rm #{buildpath}/srcfiles.tmp"
      mkdir_p "#{prefix}/lib/clang/#{clang_version}/src/compiler-rt"
      system "tar cf - -C #{buildpath} -T #{buildpath}/srcfiles.files | \
        tar xf - -C #{prefix}/lib/clang/#{clang_version}/src/compiler-rt"
    end
  end
  # install
end
# formula

# These patch series address a build issue with baremetal toolchains, where
# standard C library header files (which are not available) are used.
__END__
diff --git a/compiler-rt/lib/builtins/CMakeLists.txt b/compiler-rt/lib/builtins/CMakeLists.txt
index 73b6bead8424..b46a3bfa4af2 100644
--- a/compiler-rt/lib/builtins/CMakeLists.txt
+++ b/compiler-rt/lib/builtins/CMakeLists.txt
@@ -244,7 +244,7 @@ if (HAVE_UNWIND_H)
   )
 endif ()

-if (NOT FUCHSIA)
+if (NOT FUCHSIA AND NOT COMPILER_RT_BAREMETAL_BUILD)
   set(GENERIC_SOURCES
     ${GENERIC_SOURCES}
     clear_cache.c
