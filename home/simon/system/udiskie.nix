{ lib, ... }:
{
  services.udiskie = {
    enable = true;
    automount = false;
    notify = true;
    tray = "auto";
  };
  systemd.user.services.udiskie.Unit.After = lib.mkForce "graphical-session.target";
}
