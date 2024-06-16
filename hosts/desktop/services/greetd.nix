{
  config,
  lib,
  pkgs,
  ...
}: let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  #hyprland-session = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/share/wayland-sessions";
  sessionsData = config.services.displayManager.sessionData.desktops;
  xsessionsPath = "${sessionsData}/share/xsessions";
  wayland-sessionsPath = "${sessionsData}/share/wayland-sessions";
  #nixos = "${config.system.nixos.label}";
  kernel = "${config.boot.kernelPackages.kernel.version}";
in {
  # greetd DM with tuigreet
  services = {
    greetd = {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          user = "simon";
          command = "${tuigreet} --greeting 'NixOS: unstable, Kernel: XanMod ${kernel}' --time --asterisks --user-menu --theme 'border=cyan;button=yellow' --cmd Hyprland --sessions ${wayland-sessionsPath}:${xsessionsPath}";
        };
        initial_session = {
          command = "${lib.getExe config.programs.hyprland.package}";
          user = "simon";
        };
      };
    };
  };

  security.pam.services.greetd.enableGnomeKeyring = true;
}
