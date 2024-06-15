{pkgs, ...}: {
  fonts = {
    enableDefaultPackages = false;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Symbols Nerd Font" "Noto Serif" "Noto Color Emoji"];
        sansSerif = ["Symbols Nerd Font" "Inter" "Noto Color Emoji"];
        monospace = ["Symbols Nerd Font" "JetBrains Mono" "Noto Color Emoji"];
        emoji = ["Symbols Nerd Font" "Noto Color Emoji"];
      };
      antialias = true;
      cache32Bit = true;
      hinting.enable = true;
      hinting.autohint = true;
    };
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      jetbrains-mono
      roboto
      (google-fonts.override {fonts = ["Inter"];})
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
    ];
  };
}
