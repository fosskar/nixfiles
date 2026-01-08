{
  # arctis nova pro wireless - assign proper profile-set
  # usb id 1038:12e0 missing from pipewire udev rules, defaults to pro-audio only
  # simple-headphones-mic.conf matches device layout (stereo out + mono mic)

  services.udev.extraRules = ''
    ATTRS{idVendor}=="1038", ATTRS{idProduct}=="12e0", ENV{ACP_PROFILE_SET}="simple-headphones-mic.conf"
  '';
}
