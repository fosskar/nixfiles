{
  flake.modules.nixos.workstation =
    { lib, pkgs, ... }:
    {
      fonts = {
        enableDefaultPackages = false;
        fontDir = {
          enable = lib.mkDefault true;
          decompressFonts = lib.mkDefault true;
        };
        fontconfig = {
          defaultFonts = {
            serif = lib.mkDefault [
              "Noto Serif"
              "Noto Color Emoji"
            ];
            sansSerif = lib.mkDefault [
              "Inter"
              "Noto Color Emoji"
            ];
            monospace = lib.mkDefault [
              "CommitMono Nerd Font Propo"
              "Noto Color Emoji"
            ];
            emoji = lib.mkDefault [ "Noto Color Emoji" ];
          };
          cache32Bit = lib.mkDefault true;
          allowBitmaps = lib.mkDefault false;
          hinting = {
            autohint = lib.mkDefault true;
            style = lib.mkDefault "full";
          };
        };
        packages = [
          pkgs.inter
          pkgs.dejavu_fonts
          pkgs.liberation_ttf
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-color-emoji
          #openmoji-color
          #openmoji-black
          pkgs.roboto
          pkgs.material-icons
          pkgs.material-design-icons
          pkgs.nerd-fonts.commit-mono
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.nerd-fonts.symbols-only
          pkgs.nerd-fonts.zed-mono
        ];
      };
    };
}
