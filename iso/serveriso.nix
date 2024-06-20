{ ... }:
{
  imports = [
    ../hosts/server/core/console.nix
    ../hosts/server/core/locale.nix
    ../hosts/server/core/systemd.nix
    ../hosts/server/core/users.nix
    ../hosts/server/core/zram.nix
    ../hosts/server/hardware/fwupd.nix
    ../hosts/server/network
    ../hosts/server/nix
    ../hosts/server/pkgs/packages.nix
    ../hosts/server/programs/dconf.nix
    ../hosts/server/programs/git.nix
    ../hosts/server/programs/gnupg.nix
    ../hosts/server/programs/zsh.nix
    ../hosts/server/secrets/sops.nix
    ../hosts/server/services/podman.nix
    ../hosts/server/services/ssh.nix
    ../hosts/server/services/udev.nix
  ];

  system.stateVersion = "23.11";
}
