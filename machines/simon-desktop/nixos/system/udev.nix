{ pkgs, ... }:
{
  services.udev = {
    #packages = with pkgs; [
    #  platformio-core
    #  openocd
    #];
    extraRules = ''
      ## rules below set the scheduler to bfq for rotational drives, bfq for SSD/eMMC drives and none for NVMe drives
      # HDD
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      # SSD
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      # NVMe SSD
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"

      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"

      DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"

      KERNEL=="ntsync", MODE="0644"

      # PS4 Controller (https://github.com/epigramx/ds4drv-cemuhook/blob/master/udev/50-ds4drv.rules)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:05C4.*", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:09CC.*", MODE="0666"

      # this locks the screen when yubikey is unplugged
      ACTION=="remove", \
      ENV{ID_BUS}=="usb", \
      ENV{ID_MODEL_ID}=="0407", \
      ENV{ID_VENDOR_ID}=="1050", \
      ENV{ID_VENDOR}=="Yubico", \
      RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"

      ## Betaflight fpv rules
      # DFU (Internal bootloader for STM32 and AT32 MCUs)
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2e3c", ATTRS{idProduct}=="df11", MODE="0664", GROUP="plugdev"
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0664", GROUP="plugdev"
    '';
  };
}
