{ ... }:
{
  services.screen-locker = {
    enable = true;
    inactiveInterval = 15;
    lockCmd = "i3lock -c 000000";
    xautolock.enable = false;
  };

  #services.xidlehook = {
  #  detect-sleep = true;
  #  not-when-audio = true;
  #  not-when-fullscreen = true;
  #};
}
