{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    neofetch
    neovim
    btop
    bat
    curl
    dig
    # hypervisor
    qemu
    operator-sdk
    k9s
  ];
}
