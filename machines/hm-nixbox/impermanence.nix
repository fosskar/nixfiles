{ inputs, ... }:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  boot.initrd.systemd.services.zfs-rollback-root = {
    description = "rollback zfs root to blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "zfs-import-znixos.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      zfs rollback -r znixos/root@blank
    '';
  };
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/cache"
      "/var/lib" # nixos state (user/group ids)
      "/var/lib/sops-nix" # explizit set, so we can early mount sops secrets
    ];
    files = [
      "/etc/machine-id"
      #"/etc/ssh/ssh_host_ed25519_key"
      #"/etc/ssh/ssh_host_ed25519_key.pub"
      #"/etc/ssh/ssh_host_rsa_key"
      #"/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  fileSystems = {
    "/nix".neededForBoot = true;
    "/persist".neededForBoot = true;
    "/var/lib/sops-nix".neededForBoot = true;
  };
}
