class RiscvOpenocd < Formula
  desc "On-chip debugging, in-system programming for RISC-V"
  homepage "https://sourceforge.net/projects/openocd/"
  url "https://github.com/openocd-org/openocd/archive/refs/tags/v0.12.0-rc3.tar.gz"
  sha256 "dcf00672cbc72c17ab78596aa486a953766f05146b0ca4a1cfe8ae894bf75cc6"
  version="0.12.0-rc3"

  head do
    url "https://github.com/openocd-org/openocd.git", :tag => "v0.12.0-rc3"
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
diff --git a/src/target/riscv/riscv-013.c b/src/target/riscv/riscv-013.c
index 99d3873de..63a5a3f54 100644
--- a/src/target/riscv/riscv-013.c
+++ b/src/target/riscv/riscv-013.c
@@ -393,7 +393,7 @@ static void dump_field(int idle, const struct scan_field *field)
 	unsigned int in_data = get_field(in, DTM_DMI_DATA);
 	unsigned int in_address = in >> DTM_DMI_ADDRESS_OFFSET;
 
-	log_printf_lf(LOG_LVL_DEBUG,
+	log_printf_lf(LOG_LVL_DEBUG_IO,
 			__FILE__, __LINE__, "scan",
 			"%db %s %08x @%02x -> %s %08x @%02x; %di",
 			field->num_bits, op_string[out_op], out_data, out_address,
@@ -404,7 +404,7 @@ static void dump_field(int idle, const struct scan_field *field)
 	decode_dmi(out_text, out_address, out_data);
 	decode_dmi(in_text, in_address, in_data);
 	if (in_text[0] || out_text[0]) {
-		log_printf_lf(LOG_LVL_DEBUG, __FILE__, __LINE__, "scan", "%s -> %s",
+		log_printf_lf(LOG_LVL_DEBUG_IO, __FILE__, __LINE__, "scan", "%s -> %s",
 				out_text, in_text);
 	}
 }
diff --git a/src/target/riscv/riscv.c b/src/target/riscv/riscv.c
index 4f24fb41e..585d8dfa6 100644
--- a/src/target/riscv/riscv.c
+++ b/src/target/riscv/riscv.c
@@ -2088,7 +2088,7 @@ static enum riscv_poll_hart riscv_poll_hart(struct target *target, int hartid)
 	if (riscv_set_current_hartid(target, hartid) != ERROR_OK)
 		return RPH_ERROR;
 
-	LOG_DEBUG("polling hart %d, target->state=%d", hartid, target->state);
+	LOG_DEBUG_IO("polling hart %d, target->state=%d", hartid, target->state);
 
 	/* If OpenOCD thinks we're running but this hart is halted then it's time
 	 * to raise an event. */
@@ -2183,7 +2183,7 @@ exit:
 /*** OpenOCD Interface ***/
 int riscv_openocd_poll(struct target *target)
 {
-	LOG_DEBUG("polling all harts");
+	LOG_DEBUG_IO("polling all harts");
 	int halted_hart = -1;
 
 	if (target->smp) {
@@ -3301,7 +3301,7 @@ int riscv_set_current_hartid(struct target *target, int hartid)
 
 	int previous_hartid = riscv_current_hartid(target);
 	r->current_hartid = hartid;
-	LOG_DEBUG("setting hartid to %d, was %d", hartid, previous_hartid);
+	LOG_DEBUG_IO("setting hartid to %d, was %d", hartid, previous_hartid);
 	if (r->select_current_hart(target) != ERROR_OK)
 		return ERROR_FAIL;
 
