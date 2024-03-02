{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    neofetch
    btop
    curl
    dig
    # i3
    rofi
    i3blocks
    i3lock
    xautolock
    i3status
    # nix tooling
    alejandra
    deadnix
    statix
  ];
}
