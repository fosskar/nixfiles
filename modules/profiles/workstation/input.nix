{ lib, ... }:
{
  # libinput for mouse/trackpad
  # flat acceleration is preferred for gaming - no mouse acceleration curve
  services.libinput = {
    enable = lib.mkDefault true;
    mouse = {
      accelProfile = lib.mkDefault "flat";
      accelSpeed = lib.mkDefault "0";
    };
    touchpad = {
      naturalScrolling = lib.mkDefault true;
      disableWhileTyping = lib.mkDefault true;
    };
  };
}
