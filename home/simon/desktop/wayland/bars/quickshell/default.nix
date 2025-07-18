{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.desktop.wayland.bar;
in
{
  config = mkIf (cfg == "quickshell") {
    home = {
      packages = [
        inputs.quickshell.packages.${pkgs.system}.default
      ];

      sessionVariables.QML2_IMPORT_PATH = lib.concatStringsSep ":" [
        "${inputs.quickshell.packages.${pkgs.system}.default}/lib/qt-6/qml"
        "${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml"
        "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml"
      ];
    };
    ## Place Quickshell config files in ~/.config/quickshell/qml
    #xdg.configFile = {
    #  "quickshell".source = ./qml;
    #};
  };
}
