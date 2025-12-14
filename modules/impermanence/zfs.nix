{ cfg }:
{
  service = {
    zfs-rollback-root = {
      description = "rollback zfs root to blank snapshot";
      wantedBy = [ "initrd.target" ];
      after = [ cfg.zfs.importService ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        zfs rollback -r ${cfg.zfs.dataset}@${cfg.zfs.snapshot}
      '';
    };
  };
}
