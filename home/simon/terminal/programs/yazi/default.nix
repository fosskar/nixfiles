{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./theme/filetype.nix
    ./theme/icons.nix
    ./theme/manager.nix
    ./theme/status.nix
  ];

  # general file info
  home.packages = [ pkgs.exiftool ];

  # yazi file manager
  programs.yazi = {
    enable = true;

    package = inputs.yazi.packages.${pkgs.system}.default;

    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;

    settings = {
      manager = {
        layout = [
          0
          4
          4
        ];
        sort_by = "alphabetical";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "none";
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
    };
  };
}
