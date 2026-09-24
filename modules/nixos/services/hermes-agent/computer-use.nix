{ inputs, ... }:
{
  # background desktop control: cua-driver over MCP plus the headless X server
  # it drives. hermes' own `computer-use install` cannot run here — it shells
  # out to /bin/bash for the upstream installer — so the driver comes from nix
  # and HERMES_CUA_DRIVER_CMD points at it, which also stops hermes from
  # replacing it during its version repair
  flake.modules.nixos.hermesComputerUse =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      display = ":99";
      driver = inputs.cua.packages.${pkgs.stdenv.hostPlatform.system}.cua-driver;
      inherit (config.services.hermes-agent) user group;
      # bot desktop (the Screen pane): tools/bot_desktop/launcher.sh runs its
      # own Xvnc + Xfce per profile, separate from the Xvfb display below
      botDesktop = pkgs.buildEnv {
        name = "hermes-bot-desktop";
        paths = [
          pkgs.tigervnc
          pkgs.xfwm4
          pkgs.xfce4-panel
          pkgs.xfdesktop
          pkgs.xfce4-settings
          pkgs.xfce4-terminal
          pkgs.xfconf
          pkgs.dbus
          pkgs.xauth
          pkgs.xdpyinfo
          pkgs.setxkbmap
          pkgs.xprop
          pkgs.xsetroot
          pkgs.xset
          pkgs.adwaita-icon-theme
          pkgs.hicolor-icon-theme
        ];
        pathsToLink = [
          "/bin"
          "/share"
        ];
      };
    in
    {
      # owns org.a11y.Bus on the session bus; without it cua-driver captures
      # pixels fine but every accessibility tree comes back empty, which is
      # what capture(mode='som') numbers its elements from
      services.gnome.at-spi2-core.enable = true;

      services.hermes-agent = {
        extraPackages = [
          driver
          # capture.rs shells out to `import` for window screenshots
          pkgs.imagemagick
          botDesktop
        ];

        # computer_use is in every platform composite and gated on this
        # variable; no toolset entry needed
        environment = {
          DISPLAY = display;
          HERMES_CUA_DRIVER_CMD = lib.getExe driver;
          # dbus-run-session finds xfconfd only through XDG_DATA_DIRS; without
          # it xfce ignores the launcher's seeded panel and theme config
          XDG_DATA_DIRS = "${botDesktop}/share";
        };
      };

      systemd.services.hermes-xvfb = {
        description = "virtual display for the Hermes agent";
        wantedBy = [ "multi-user.target" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          ExecStart = "${lib.getExe' pkgs.xorg-server "Xvfb"} ${display} -screen 0 1920x1080x24 -nolisten tcp";
          User = user;
          Group = group;
          Restart = "always";
          RestartSec = 5;
        };
      };

      # cua-driver resolves windows through EWMH properties that only a window
      # manager sets; a bare Xvfb reports no windows at all
      systemd.services.hermes-openbox = {
        description = "window manager on the Hermes virtual display";
        wantedBy = [ "multi-user.target" ];
        after = [ "hermes-xvfb.service" ];
        requires = [ "hermes-xvfb.service" ];
        environment.DISPLAY = display;
        serviceConfig = {
          ExecStart = lib.getExe' pkgs.openbox "openbox";
          User = user;
          Group = group;
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
