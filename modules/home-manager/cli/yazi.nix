{
  flake.modules.homeManager.yazi =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.exiftool ];

      programs.yazi = {
        enable = true;
        shellWrapperName = "y";

        settings = {
          mgr = {
            ratio = [
              0
              4
              4
            ];
            linemode = "size";
            show_hidden = true;
          };

          preview.image_quality = 90;
          opener = {
            edit = [
              {
                run = ''micro "$@"'';
                desc = "$EDITOR";
                block = true;
                for = "unix";
              }
            ];
            open = [
              {
                run = ''xdg-open "$@"'';
                desc = "Open";
                for = "linux";
              }
            ];
            reveal = [
              {
                run = ''${lib.getExe pkgs.exiftool} "$1"; echo "Press enter to exit"; read _'';
                block = true;
                desc = "Show EXIF";
                for = "unix";
              }
            ];
            play = [
              {
                run = ''${lib.getExe pkgs.mpv} "$@"'';
                orphan = true;
                for = "unix";
              }
              {
                run = ''${lib.getExe pkgs.mediainfo} "$1"; echo "Press enter to exit"; read _'';
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
