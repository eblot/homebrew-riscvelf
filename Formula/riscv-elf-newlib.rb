require "formula"

class RiscvElfNewlib < Formula
  desc "C libraries for baremetal RISC-V targets"
  homepage "https://sourceware.org/newlib/"
  url "ftp://sourceware.org/pub/newlib/newlib-4.4.0.20231231.tar.gz"
  sha256 "0c166a39e1bf0951dfafcd68949fe0e4b6d3658081d6282f39aeefc6310f2f13"
  version "4.4.0"

  option "with-debug", "Build libraries in debug mode"

  depends_on "riscv-elf-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python" => :build
  depends_on "texinfo" => :build
  depends_on "coreutils" => :build if OS.mac?

  # should not install as a system library
  keg_only "conflict with system"

  # note: linuxbrew is not supported

  def install
    llvm = Formulary.factory "riscv-elf-llvm"

    ENV.append_path "PATH", "#{llvm.bin}"

    ENV["CC_FOR_TARGET"] = "#{llvm.bin}/clang"
    ENV["AR_FOR_TARGET"] = "#{llvm.bin}/llvm-ar"
    ENV["NM_FOR_TARGET"] = "#{llvm.bin}/llvm-nm"
    ENV["RANLIB_FOR_TARGET"] = "#{llvm.bin}/llvm-ranlib"
    ENV["READELF_FOR_TARGET"] = "#{llvm.bin}/llvm-readelf"
    ENV["AS_FOR_TARGET"] = "#{llvm.bin}/clang"

    newlib_args = %W[
        --disable-malloc-debugging
        --disable-newlib-atexit-dynamic-alloc
        --disable-newlib-fseek-optimization
        --disable-newlib-fvwrite-in-streamio
        --disable-newlib-iconv
        --disable-newlib-mb
        --disable-newlib-supplied-syscalls
        --disable-newlib-wide-orient
        --disable-nls
        --enable-lite-exit
        --enable-newlib-multithread
        --enable-newlib-reent-small
        --enable-newlib-nano-malloc
        --enable-newlib-global-atexit
        --enable-newlib-io-long-double
        --enable-newlib-io-long-long
        --enable-newlib-io-c99-formats
        --disable-newlib-unbuf-stream-opt
        --enable-newlib-io-c99-formats
        --disable-newlib-nano-formatted-io
    ]

    host=`cc -dumpmachine`.strip

    if build.with? "debug"
      xopts = "-g -Og"
    else
      xopts="-Oz"
    end

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

          xtarget = "riscv#{xlen}-unknown-elf"
          xarch = "rv#{xlen}#{abi}"
          xctarget = "-march=#{xarch} -mabi=#{xabi}#{xlen}#{xabix} #{xmodel}"
          xarchdir = xarch.gsub(/[0-9]+p[0-9]+/, '')
          xcfeatures = "-ffunction-sections -fdata-sections -fno-stack-protector -fvisibility=hidden"
          xcflags = "#{xctarget} #{xopts} #{xcfeatures}"

          if xarch.match(/[0-1]+p[0-9]+/)
            xcflags = "#{xcflags} -menable-experimental-extensions"
          end
          # remap source file path so that it is possible to step-debug system
          # library files (see below)
          xncflags = "#{xcflags} -fdebug-prefix-map=#{buildpath}=#{prefix}/src"

          # newlib should be fixed...
          warnings="-Wno-unused-command-line-argument -Wno-implicit-function-declaration " \
                   "-Wno-unknown-pragmas -Wno-deprecated-non-prototype -Wno-pointer-sign " \
                   "-Wno-int-conversion"
          ENV["CFLAGS_FOR_TARGET"] = "-target #{xtarget} #{xncflags} #{warnings}"

          mktemp do
            puts "--- #{xarch}/#{xabi}#{xlen}#{xabix}#{compact} ---"
            system "#{buildpath}/configure",
                      "--host=#{host}",
                      "--build=#{host}",
                      "--target=#{xtarget}",
                      "--prefix=#{prefix}",
                      *newlib_args
            system "make"
            # deparallelise (-j1) is required or installer fails to create output dir
            system "make -j1 install; true"
            # move to similar dir as GCC multilib toolchain
            mkdir_p "#{prefix}/include"
            system "(tar cf - -C #{prefix}/#{xtarget}/include . | \
                     tar xf - -C #{prefix}/include)"
            # remove always present directory, whatever xarch is built
            system "rm -rf #{prefix}/#{xtarget}/lib/rv64imafdc"
            mkdir_p "#{prefix}/lib/#{xarchdir}/#{xabi}#{xlen}#{xabix}#{compact}"
            system "(tar cf - -C #{prefix}/#{xtarget}/lib . | \
                     tar xf - -C #{prefix}/lib/#{xarchdir}/#{xabi}#{xlen}#{xabix}#{compact})"
            # remove initial installation path"
            system "rm -rf #{prefix}/#{xtarget}"
            # remove useless iconv data
            system "rm -rf #{prefix}/#{xtarget}/share/iconv_data"
          end
          # newlib

          if build.with? "debug"
            # extract the list of actually used source files, so they can be copied
            # into the destination tree (so that it is possible to step-debug in
            # the system libraries)
            system "llvm-dwarfdump #{prefix}/lib/#{xarchdir}/#{xabi}#{xlen}#{xabix}#{compact}/*.a | \
              grep DW_AT_decl_file | tr -d ' ' | cut -d'\"' -f2 \
              >> #{buildpath}/srcfiles.tmp"
          end
        end
        # for isa
      end
      # for compact
    end
    # for xlen

    if build.with? "debug"
      # find unique source files, would likely be easier in Ruby,
      # but Ruby is dead - or should be :-)
      # newlib/ files and compiler-rt are handled one after another, as newlib
      # as an additional directory level
      # realpath is required to resolve ../ path specifier, which are otherwise
      # trash by tar, leading to invalid path (maybe cpio would be better here?)
      puts "--- library source files ---"
      system "sort -u #{buildpath}/srcfiles.tmp"
      system "sort -u #{buildpath}/srcfiles.tmp | grep -E '/(newlib|libgloss)/' | \
        sed 's%^#{prefix}/src/%%' | grep -v '^/' | \
        (xargs -n 1 realpath --relative-to .) \
          > #{buildpath}/newlib.files"
      system "cat #{buildpath}/newlib.files"
      system "rm #{buildpath}/srcfiles.tmp"
      mkdir_p "#{prefix}/src"
      system "tar cf - -C #{buildpath} -T #{buildpath}/newlib.files | \
        tar xf - -C #{prefix}/src"
    end
  end
  # install
end
# formula
