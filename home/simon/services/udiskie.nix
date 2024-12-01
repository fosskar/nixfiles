{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.services.udiskie;
in
{
  options.module.services.udiskie = {
    enable = mkEnableOption "Enable udiskie";
  };

  config = mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      automount = false;
      notify = true;
      tray = "auto";
    };
    systemd.user.services.udiskie.Unit.After = lib.mkForce "graphical-session.target";
  };
}
