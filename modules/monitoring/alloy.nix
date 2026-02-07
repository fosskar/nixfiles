{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.monitoring.alloy;
  alloyCfg = config.services.alloy;

  # combine clan-core's config (via configPath) with extra config in a directory
  configDir = pkgs.runCommand "alloy-config" { } ''
    mkdir -p $out
    ln -s ${alloyCfg.configPath} $out/monitoring.alloy
    cp ${pkgs.writeText "extra.alloy" cfg.extraConfig} $out/extra.alloy
  '';
in
{
  options.nixfiles.monitoring.alloy.extraConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "extra alloy configuration blocks appended alongside the clan-core base config";
  };

  config = lib.mkIf (cfg.extraConfig != "" && alloyCfg.enable) {
    # override ExecStart to use combined config directory instead of clan-core's single file.
    # we read configPath (set by clan-core) but override ExecStart, avoiding circular dependency.
    systemd.services.alloy.serviceConfig.ExecStart =
      lib.mkForce "${lib.getExe alloyCfg.package} run ${configDir} ${lib.escapeShellArgs alloyCfg.extraFlags}";
  };
}
