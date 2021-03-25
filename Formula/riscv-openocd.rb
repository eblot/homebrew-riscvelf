class RiscvOpenocd < Formula
  desc "On-chip debugging, in-system programming for RISC-V"
  homepage "https://sourceforge.net/projects/openocd/"

  head do
    url "https://github.com/riscv/riscv-openocd.git", :branch => "riscv"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build

  depends_on "libftdi"
  depends_on "libusb"

  keg_only "conflict with upstream openocd"

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-verbose
      --enable-verbose-jtag-io
      --enable-verbose-usb-io
      --enable-verbose-usb-comms
      --enable-ftdi
      --enable-jlink
      --enable-remote-bitbang
      --disable-doxygen-html
      --disable-doxygen-pdf
      --disable-werror
      --disable-dummy
      --disable-stlink
      --disable-ti-icdi
      --disable-ulink
      --disable-usb-blaster-2
      --disable-ft232r
      --disable-vsllink
      --disable-xds110
      --disable-osbdm
      --disable-opendous
      --disable-aice
      --disable-usbprog
      --disable-rlink
      --disable-armjtagew
      --disable-kitprog
      --disable-usb-blaster
      --disable-presto
      --disable-openjtag
      --disable-parport
      --disable-jtag_vpi
      --disable-amtjtagaccel
      --disable-zy1000-master
      --disable-zy1000
      --disable-ep93xx
      --disable-at91rm9200
      --disable-bcm2835gpio
      --disable-imx_gpio
      --disable-gw16012
      --disable-oocd_trace
      --disable-buspirate
      --disable-sysfsgpio
      --disable-minidriver-dummy
    ]

    system "./bootstrap"
    system "./configure", *args
    system "make", "install"
  end
end
