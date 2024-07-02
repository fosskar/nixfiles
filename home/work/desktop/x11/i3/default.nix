{ ... }:
{
  imports = [
    ./config.nix
    ./i3status-rust.nix
    ../lock.nix
    ../rofi.nix
    ../dunst.nix
  ];
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
    };
  };
}
