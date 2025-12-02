{
  lib,
  inputs,
  config,
  mylib,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  fileSystems = {
    "/persist".neededForBoot = true;
    "/nix".neededForBoot = true;
  };

  # point agenix to use the persisted ssh key directly
  #age.identityPaths = [
  #  "/persist/etc/ssh/ssh_host_ed25519_key"
  #];

  environment.persistence."/persist" = {
    hideMounts = lib.mkDefault true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      {
        directory = "/var/lib/sops-nix";
        mode = "0755";
      }
    ];
    files = [
      (lib.mkIf (!config.boot.isContainer) "/etc/machine-id")
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
