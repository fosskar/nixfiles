{ config, ... }:
{
  # add wheel users to plugdev group for Betaflight DFU
  users.groups.plugdev.members = config.users.groups.wheel.members;

  services.udev.extraRules = ''
    # betaflight fpv rules - DFU (internal bootloader for STM32 and AT32 MCUs)
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2e3c", ATTRS{idProduct}=="df11", MODE="0664", GROUP="plugdev"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0664", GROUP="plugdev"
  '';
}
