class RiscvOpenocd < Formula
  desc "On-chip debugging, in-system programming for RISC-V"
  homepage "https://sourceforge.net/projects/openocd/"
  # url "https://github.com/openocd-org/openocd/archive/refs/tags/v0.12.0-rc1.tar.gz"
  # sha256 "dcf00672cbc72c17ab78596aa486a953766f05146b0ca4a1cfe8ae894bf75cc6"
  # version="0.12.0-rc1"

  head do
    url "https://github.com/openocd-org/openocd.git", :tag => "v0.12.0-rc1"
    patch :DATA
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
    system "make"
    system "make", "install"
  end
end

__END__
diff --git a/src/flash/nor/spi.c b/src/flash/nor/spi.c
index eed747b58..83075c281 100644
--- a/src/flash/nor/spi.c
+++ b/src/flash/nor/spi.c
@@ -113,6 +113,7 @@ const struct flash_device flash_devices[] = {
 	FLASH_ID("gd gd25q256c",        0x13, 0x00, 0x12, 0xdc, 0xc7, 0x001940c8, 0x100, 0x10000, 0x2000000),
 	FLASH_ID("gd gd25q512mc",       0x13, 0x00, 0x12, 0xdc, 0xc7, 0x002040c8, 0x100, 0x10000, 0x4000000),
 	FLASH_ID("issi is25lp032",      0x03, 0x00, 0x02, 0xd8, 0xc7, 0x0016609d, 0x100, 0x10000, 0x400000),
+	FLASH_ID("issi is25lq040b",     0x13, 0xeb, 0x02, 0xd8, 0xc7, 0x0013409d, 0x100, 0x10000, 0x80000),
 	FLASH_ID("issi is25lp064",      0x03, 0x00, 0x02, 0xd8, 0xc7, 0x0017609d, 0x100, 0x10000, 0x800000),
 	FLASH_ID("issi is25lp128d",     0x03, 0xeb, 0x02, 0xd8, 0xc7, 0x0018609d, 0x100, 0x10000, 0x1000000),
 	FLASH_ID("issi is25wp128d",     0x03, 0xeb, 0x02, 0xd8, 0xc7, 0x0018709d, 0x100, 0x10000, 0x1000000),
