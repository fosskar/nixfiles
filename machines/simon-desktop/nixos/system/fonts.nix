{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = false;
    fontDir = {
      enable = true;
      decompressFonts = true;
    };
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "Noto Serif"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Inter"
          "Noto Color Emoji"
        ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
      antialias = true;
      includeUserConf = true;
      cache32Bit = true;
      allowBitmaps = false;
      allowType1 = false; # Poor rendering
      hinting = {
        enable = true;
        autohint = true;
        style = "full";
      };
    };
    packages = with pkgs; [
      # defaults worth keeping
      inter
      dejavu_fonts
      liberation_ttf # for PDFs, Roman
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      openmoji-color
      openmoji-black
      roboto
      material-icons # used in widgets and such
      material-design-icons
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      nerd-fonts.zed-mono
    ];
  };
}
