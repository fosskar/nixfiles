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
      cache32Bit = true;
      hinting = {
        enable = true;
        autohint = true;
      };
    };
    packages = with pkgs; [
      # defaults worth keeping
      dejavu_fonts
      liberation_ttf # for PDFs, Roman
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      openmoji-color
      openmoji-black
      roboto
      material-icons # used in widgets and such
      material-design-icons
      (google-fonts.override { fonts = [ "Inter" ]; })
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "NerdFontsSymbolsOnly"
        ];
      })
    ];
  };
}
