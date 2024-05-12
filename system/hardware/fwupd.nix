{pkgs, ...}: {
  hardware.firmware = with pkgs; [
    linux-firmware
    alsa-firmware
  ];
  services.fwupd.enable = true;
}
