{
  config,
  lib,
  pkgs,
  ...
}:
let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  #hyprland-session = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/share/wayland-sessions";
  sessionsData = config.services.displayManager.sessionData.desktops;
  sessionsPaths = lib.concatStringsSep ":" [
    "${sessionsData}/share/xsessions"
    "${sessionsData}/share/wayland-sessions"
  ];
  #nixos = "${config.system.nixos.label}";
  kernel = "${config.boot.kernelPackages.kernel.version}";
in
{
  # greetd DM with tuigreet
  services = {
    greetd = {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          user = "simon";
          command = "${tuigreet} --greeting 'NixOS: unstable, Kernel: XanMod ${kernel}' --time --asterisks --remember --remember-user-session  --theme 'border=cyan;button=yellow' --cmd Hyprland --sessions '${sessionsPaths}'";
        };
        #initial_session = {
        #  command = "${lib.getExe config.programs.hyprland.package}";
        #  user = "simon";
        #};
      };
    };
  };

  # Suppress error messages on tuigreet. They sometimes obscure the TUI
  # boundaries of the greeter.
  # See: https://github.com/apognu/tuigreet/issues/68#issuecomment-1586359960
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    #StandardInputs = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
