{ pkgs, ... }:
{
  users.users.simon = {
    isNormalUser = true;
    createHome = true;
    home = "/home/simon";
    initialPassword = "123";
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
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
      "nix"
      "network"
    ];
  };
}
