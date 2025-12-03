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
      zfs rollback -r znixos/root@blank && echo '  >> >> rollback complete << <<'
    '';
  };
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/var/cache"
      #"/var/lib/nixos" # nixos state (user/group ids)
      #"/var/lib/systemd" # systemd state (timers, etc)
      #"/var/lib/sops-nix" # sops secrets
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
