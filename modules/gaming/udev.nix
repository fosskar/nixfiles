{ lib, config, ... }:
let
  cfg = config.nixfiles.gaming;
in
{
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # ntsync for wine/proton
      KERNEL=="ntsync", MODE="0644"

      # PS4 controller
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:05C4.*", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:09CC.*", MODE="0666"
    '';
  };
}
