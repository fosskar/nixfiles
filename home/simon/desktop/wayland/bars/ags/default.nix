{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.module.desktop.wayland.bar;
in
{
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  config = mkIf (cfg == "ags") {
    programs.ags = {
      enable = true;
      configDir = ../ags;
      systemd = {
        enable = true;
      };
    };
    home.packages = with pkgs; [
      bun # needed
      dart-sass # needed
      fd # needed
      swww # needed
    ];
  };
}
