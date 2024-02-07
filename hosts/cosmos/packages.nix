{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    neofetch
    neovim
    linuxPackages.cpupower
    btop
    bat
    curl
    alejandra
    corectrl
    dig
    lm_sensors
    # Hyprland
    waybar
    wlogout
    wl-clipboard
    hyprpicker
    grim
    slurp
    # i3
    rofi
    i3blocks
    i3lock
    xautolock
    i3status
    i3-gaps
  ];
}
