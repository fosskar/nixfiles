{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  #agsConfig =
  #  pkgs.fetchFromGitHub {
  #    owner = "Jas-SinghFSU";
  #    repo = "HyprPanel ";
  #    rev = "master";
  #    sha256 = pkgs.lib.fakeSha256; # used to get the latest hash
  #    #sha256 = "2zDH36hBRnKLwtoYYMhWBaqukm2NMs0t32n1JbSooOE=";
  #  }
  #  + "/ags";

  agsDirectory = inputs.hyprpanel.outPath;
in
{
  imports = [ inputs.ags.homeManagerModules.ags ];

  home.packages = with pkgs; [
    bun # needed
    dart-sass # needed

    #optional
    brightnessctl
    #bluez
    #bluez-utils
    #grimblast
    gpu-screen-recorder
    #python
    gpustat
  ];

  programs.ags = {
    enable = true;
    configDir = ./hyprpanel;
  };

  #xdg.configFile."ags".source = config.lib.file.mkOutOfStoreSymlink agsDirectory;
  #home.file.".config/ags".source = lib.file.mkOutOfStoreSymlink agsDirectory;

  #home.file.".config/ags/hyprpanel.json".text = ''
  #  {
  #      "0": {
  #          "left": [
  #              "dashboard",
  #              "workspaces",
  #              "windowtitle"
  #          ],
  #          "middle": [
  #              "media"
  #          ],
  #          "right": [
  #              "volume",
  #              "clock",
  #              "notifications"
  #          ]
  #      },
  #      "1": {
  #          "left": [
  #              "dashboard",
  #              "workspaces",
  #              "windowtitle"
  #          ],
  #          "middle": [
  #              "media"
  #          ],
  #          "right": [
  #              "volume",
  #              "clock",
  #              "notifications"
  #          ]
  #      },
  #      "2": {
  #          "left": [
  #              "dashboard",
  #              "workspaces",
  #              "windowtitle"
  #          ],
  #          "middle": [
  #              "media"
  #          ],
  #          "right": [
  #              "volume",
  #              "network",
  #              "bluetooth",
  #              "systray",
  #              "clock",
  #              "notifications"
  #          ]
  #      }
  #  }
  #'';
}
