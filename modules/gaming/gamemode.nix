{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.gaming;
in
{
  config = lib.mkIf (cfg.enable && cfg.gamemode.enable) {
    users.groups.gamemode.members = config.users.groups.wheel.members;

    programs.gamemode = {
      enable = true;
      # enableRenice defaults to true
      settings = {
        general = {
          softrealtime = "auto";
          renice = 15;
          inhibit_screensaver = 0;
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
}
