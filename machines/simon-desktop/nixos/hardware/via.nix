{ pkgs, ... }:
{
  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = with pkgs; [
    via
    vial
    qmk
  ];
  services.udev = {
    packages = with pkgs; [
      qmk
      qmk-udev-rules # the only relevant
      qmk_hid
      via
      vial
    ];
    extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0a11", MODE="0666", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0a11", OWNER="simon", GROUP="users", MODE="0666"
    '';
  };
}
