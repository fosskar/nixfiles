{ lib, ... }:
{
  services.udiskie = {
    enable = false;
    automount = false;
    notify = true;
    tray = "auto";
  };
  systemd.user.services.udiskie.Unit.After = lib.mkForce "graphical-session.target";
}
