{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.terminal.programs.yazi;
in
{

  imports = [
    ./theme/filetype.nix
    ./theme/icons.nix
    ./theme/manager.nix
    ./theme/status.nix
  ];

  options.module.terminal.programs.yazi = {
    enable = mkEnableOption "Enable yazi";
  };

  config = mkIf cfg.enable {
    # general file info
    home.packages = [ pkgs.exiftool ];

    # yazi file manager
    programs.yazi = {
      enable = true;

      # when using input so latest from git
      #package = inputs.yazi.packages.${pkgs.system}.default;

      settings = {
        manager = {
          layout = [
            0
            4
            4
          ];
          sort_by = "alphabetical";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          linemode = "size";
          show_hidden = true;
          show_symlink = true;
        };

        preview = {
          tab_size = 2;
          max_width = 600;
          max_height = 900;
          image_filter = "triangle";
          image_quality = 90;
          sixel_fraction = 15;
          ueberzug_scale = 1;
          ueberzug_offset = [
            0
            0
            0
            0
          ];
          cache_dir = "${config.xdg.cacheHome}";
        };
        opener = {
          edit = [
            {
              run = "nvim \"$@\"";
              desc = "$EDITOR";
              block = true;
              for = "unix";
            }
          ];
          open = [
            {
              run = "xdg-open \"$@\"";
              desc = "Open";
              for = "linux";
            }
          ];
          reveal = [
            {
              run = "${lib.getExe pkgs.exiftool} \"$1\"; echo \"Press enter to exit\"; read _";
              block = true;
              desc = "Show EXIF";
              for = "unix";
            }
          ];
          play = [
            {
              run = "${lib.getExe pkgs.mpv} \"$@\"";
              orphan = true;
              for = "unix";
            }
            {
              run = "${lib.getExe pkgs.mpv} \"%1\"";
              orphan = true;
              for = "windows";
            }
            {
              run = "${lib.getExe pkgs.mediainfo} \"$1\"; echo \"Press enter to exit\"; read _";
              block = true;
              desc = "Show media info";
              for = "unix";
            }
          ];
        };
      };
    };
  };
}
