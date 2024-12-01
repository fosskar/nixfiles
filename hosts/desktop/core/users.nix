{ pkgs, ... }:
{
  users = {
    users.simon = {
      isNormalUser = true;
      createHome = true;
      home = "/home/simon";
      initialPassword = "123";
      useDefaultShell = false;
      shell = pkgs.fish;
      extraGroups = [
        "audio"
        "disk"
        "corectrl"
        "gamemode" # https://nixos.wiki/wiki/Gamemode#Known_Errors
        "input"
        "networkmanager"
        "video"
        "wheel"
        "power"
        "podman"
        "git"
        "libvirtd"
        "qemu-libvirtd"
        "kvm"
        "nix"
        "network"
      ];
    };
    defaultUserShell = pkgs.zsh; # set default shell for ALL users
  };
}
