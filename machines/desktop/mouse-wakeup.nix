_: {
  # usbhid arms remote wakeup on the logitech receiver because it exposes a boot
  # keyboard interface; mouse reports during s3 entry aborted idle suspends
  # ("Wakeup pending. Abort CPU freeze"). keychron and power button still wake.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="046d", ATTR{idProduct}=="c094", ATTR{power/wakeup}="disabled"
  '';
}
