class RiscvOpenocd < Formula
  desc "On-chip debugging, in-system programming for RISC-V"
  homepage "https://sourceforge.net/projects/openocd/"

  # openocd developers' official web site is utterly buggy and unstable
  url "https://github.com/ntfreak/openocd.git", :tag => "v0.11.0"
  version "0.11.0-elf64"
  # sha256 "d55761fbabf0d2695099fb963be29fbc3300f2ef10807653918e6bb1bedc6284"

  patch do
    # enable ELF64 loading
    url "https://gist.githubusercontent.com/sifive-eblot/a5299eb1f132a00bf45ad97dff4fe78d/raw/44f9488f6955da020b6022c7dadc7150aef04302/elf64.patch"
    sha256 "591938057d88a9f178a7e9ef8614d8c8fb9a353f7a52b616dcc90b066315b53e"
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
