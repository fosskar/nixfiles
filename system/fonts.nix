{
  pkgs,
  config,
  ...
}: {
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" "Noto Color Emoji"];
        sansSerif = ["Noto Sans CJK SC" "Noto Sans CJK TC" "Noto Sans CJK JP" "Noto Color Emoji"];
        monospace = ["FiraCode Nerd Font" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
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
      roboto
      liberation_ttf
      fira-code
      fira-code-symbols
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "JetBrainsMono"
          "FiraMono"
        ];
      })
    ];
  };
}
