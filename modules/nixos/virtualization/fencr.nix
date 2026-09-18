{
  flake.modules.nixos.fencr =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    {
      key = "nixfiles.fencr";
      imports = [ flake-self.inputs.fencr.nixosModules.fencr ];

      # whoever is root on the host is root in its vms; the clan sshd
      # service puts the operator's yubikey keys there
      fencr.adminKeys = config.users.users.root.openssh.authorizedKeys.keys;

      # per-vm cpu/rss for the fencr dashboard; the glob needs include_systemd_children
      services.telegraf.extraConfig.inputs.procstat = [
        {
          systemd_unit = "fencr-*.service";
          include_systemd_children = true;
          fieldinclude = [
            "cpu_usage"
            "memory_rss"
            "num_threads"
            "created_at"
          ];
        }
      ];

      # a fresh checkpoint of every vm's state disk for borg
      clan.core.state.agent-vms = {
        folders = [ "/var/backup/agent-vms" ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              pkgs.rsync
              pkgs.coreutils
              pkgs.systemd
            ]
          }
          set -eu
          mkdir -p /var/backup
          staging=$(mktemp -d /var/backup/agent-vms.XXXXXX)
          checkpoint=$(basename "$staging")
          cleanup() {
            for name in ${lib.escapeShellArgs (lib.attrNames config.fencr.vms)}; do
              rm -f "/var/lib/fencr-vms/$name/checkpoints/$checkpoint.img"
            done
            rm -rf -- "$staging"
          }
          trap cleanup EXIT
          for name in ${lib.escapeShellArgs (lib.attrNames config.fencr.vms)}; do
            systemctl start "fencr-$name-checkpoint@$checkpoint.service"
            mkdir -m 0700 "$staging/$name"
            cp -p --reflink=auto --sparse=always "/var/lib/fencr-vms/$name/checkpoints/$checkpoint.img" "$staging/$name/state.img"
          done
          mkdir -p /var/backup/agent-vms
          rsync -a --sparse --delete "$staging/" /var/backup/agent-vms/
        '';
      };
    };
}
