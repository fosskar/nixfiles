{
  flake.modules.nixos.gamemode =
    { config, pkgs, ... }:
    {
      users.groups.gamemode.members = config.users.groups.wheel.members;

      programs.gamemode = {
        enable = true;
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
