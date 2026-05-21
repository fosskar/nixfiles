{
  flake.modules.homeManager.bat =
    { lib, pkgs, ... }:
    {
      programs.bat = {
        enable = true;

        config = {
          style = "auto,header-filesize";
        };

        extraPackages = [
          pkgs.bat-extras.batdiff
          pkgs.bat-extras.batgrep
          pkgs.bat-extras.batman
          pkgs.bat-extras.batpipe
          pkgs.bat-extras.batwatch
          pkgs.bat-extras.prettybat
        ];
      };
      home.shellAliases = {
        cat = "${lib.getExe pkgs.bat} --style=plain";
      };
    };
}
