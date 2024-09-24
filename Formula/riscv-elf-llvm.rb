require "formula"

class RiscvElfLlvm < Formula
  homepage "https://llvm.org//"
  desc "Next-gen compiler for baremetal RISC-V targets"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.0/llvm-project-19.1.0.src.tar.xz"
  sha256 "5042522b49945bc560ff9206f25fb87980a9b89b914193ca00d961511ff0673c"

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
      -DLLVM_ENABLE_Z3_SOLVER=ON
    ]

    # Force LLDB_USE_SYSTEM_DEBUGSERVER, otherwise LLDB build fails miserably,
    # trying to link host backend object files while target backend has been
    # built.

    mkdir "build" do
      system "cmake", "-G", "Ninja", "../llvm", *(std_cmake_args + args)
      system "ninja"
      system "ninja", "install"
    end
  end
end
