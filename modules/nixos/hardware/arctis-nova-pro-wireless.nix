{
  flake.modules.nixos.arctisNovaProWireless = {
    # usb id 1038:12e0 missing from pipewire udev rules; force matching profile-set

    services.udev.extraRules = ''
      ATTRS{idVendor}=="1038", ATTRS{idProduct}=="12e0", ENV{ACP_PROFILE_SET}="simple-headphones-mic.conf"
    '';
  };
}
