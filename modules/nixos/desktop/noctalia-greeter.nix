{
  flake.modules.nixos.noctalia-greeter =
    { config, pkgs, ... }:
    {
      services.greetd = {
        enable = true;
        settings.default_session = {
          # pin niri as the default session (overrides last-used at open).
          command = "${pkgs.custom.noctalia-greeter}/bin/noctalia-greeter-session -- --session niri";
          user = "greeter";
        };
      };

      # registers the apply-appearance polkit action plus binary so noctalia-shell
      # (Settings -> Noctalia Greeter -> Sync Now) can sync wallpaper/palette.
      environment.systemPackages = [ pkgs.custom.noctalia-greeter ];

      # the greeter scans the hardcoded /usr/share/wayland-sessions; point it at
      # the wayland session desktop files collected by the display manager.
      systemd.tmpfiles.settings."10-noctalia-greeter" = {
        "/var/lib/noctalia-greeter".d = {
          user = "greeter";
          group = "greeter";
          mode = "0755";
        };
        "/usr/share/wayland-sessions".L.argument =
          "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
      };

      # greeter state (synced appearance, remembered scheme) lives here.
      preservation.preserveAt."/persist".directories = [
        {
          directory = "/var/lib/noctalia-greeter";
          user = "greeter";
          group = "greeter";
        }
      ];
    };
}
