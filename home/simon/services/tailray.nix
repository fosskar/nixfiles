{
  config,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.module.services.tailray;
in
{

  imports = [ inputs.tailray.homeManagerModules.default ];

  options.module.services.tailray = {
    enable = mkEnableOption "Enable tailray";
  };

  config = mkIf cfg.enable {

    # tailscale systray
    services.tailray.enable = true;

    systemd.user.services.tailray.Unit.After = lib.mkForce "graphical-session.target";
  };

}
