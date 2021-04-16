require "formula"

class RiscvElfLlvm < Formula
  desc "Next-gen compiler for baremetal RISC-V targets"
  homepage "https://llvm.org/"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.0/llvm-project-12.0.0.src.tar.xz"
    sha256 "9ed1688943a4402d7c904cc4515798cdb20080066efa010fe7e1f2551b423628"
  end

  head do
    url "https://github.com/llvm/llvm-project", :using => :git, :tag => "llvmorg-12.0.0-rc5"
  end

  # beware that forcing link may seriously break your installation, as
  # some header files may be symlinked in /usr/local/include and /usr/local/lib
  # which can in turn be included/loaded by the system toolchain...
  keg_only "conflict with system llvm"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "swig" => :build
  depends_on "libedit"
  depends_on "ncurses"
  depends_on "python"
  depends_on "z3"

  def install
    args = %w[
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld
      -DLLVM_ENABLE_SPHINX=False
      -DLLVM_INCLUDE_TESTS=False
      -DLLVM_TARGETS_TO_BUILD=RISCV
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_DEFAULT_TARGET_TRIPLE=riscv64-elf
      -DCMAKE_CROSSCOMPILING=ON
      -DLLDB_USE_SYSTEM_DEBUGSERVER=ON
      -DLLVM_OPTIMIZED_TABLEGEN=ON
    ]

    # Force LLDB_USE_SYSTEM_DEBUGSERVER, otherwise LLDB build fails miserably,
    # trying to link host backend object files while target backend has been
    # built.

    mkdir "build" do
      system "cmake", "-G", "Ninja", "../llvm", *(std_cmake_args + args)
      system "ninja"
      system "ninja", "install"
      # add man files that do not get automatically installed
      system "mkdir -p #{man1} #{man7}"
      system "cp ../lld/docs/ld.lld.1 ../llvm/docs/llvm-objdump.1 #{man1}"
      system "cp ../llvm/docs/re_format.7 #{man7}"
    end
  end
end
