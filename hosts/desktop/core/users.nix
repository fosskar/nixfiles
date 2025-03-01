{ pkgs, ... }:
{
  users = {
    users.simon = {
      isNormalUser = true;
      createHome = true;
      home = "/home/simon";
      initialPassword = "123";
      shell = pkgs.fish;
      extraGroups = [
        "audio"
        "disk"
        "gamemode"
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
  };
}
