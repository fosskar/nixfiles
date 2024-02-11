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
    dig
    lm_sensors
    radeon-profile
    lact
    # Hyprland
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
  ];
}
