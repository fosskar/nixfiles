{ lib, pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = false;
    fontDir = {
      enable = lib.mkDefault true;
      decompressFonts = lib.mkDefault true;
    };
    fontconfig = {
      enable = lib.mkDefault true;
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
      antialias = lib.mkDefault true;
      includeUserConf = lib.mkDefault true;
      cache32Bit = lib.mkDefault true;
      allowBitmaps = lib.mkDefault false;
      allowType1 = lib.mkDefault false;
      hinting = {
        enable = lib.mkDefault true;
        autohint = lib.mkDefault true;
        style = lib.mkDefault "full";
      };
    };
    packages = with pkgs; [
      inter
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      openmoji-color
      openmoji-black
      roboto
      material-icons
      material-design-icons
      nerd-fonts.commit-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      nerd-fonts.zed-mono
    ];
  };
}
