{ cfg }:
{
  service = {
    zfs-rollback-root = {
      description = "rollback zfs root to blank snapshot";
      wantedBy = [ "initrd.target" ];
      after = [ cfg.rollback.poolImportService ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        zfs rollback -r ${cfg.rollback.dataset}@${cfg.rollback.snapshot}
      '';
    };
  };
}
