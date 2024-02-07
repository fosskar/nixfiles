{pkgs, ...}: {
  home.packages = with pkgs; [
    fira-mono
    fira-code
    fira-code-symbols
    fira-code-nerdfont
    liberation_ttf
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    roboto
    monaspace
  ];

  fonts.fontconfig.enable = true;
}
