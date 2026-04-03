{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.nixfiles.buildbot.worker;
in
{
  imports = [ inputs.buildbot-nix.nixosModules.buildbot-worker ];

  options.nixfiles.buildbot.worker = {
    enable = lib.mkEnableOption "buildbot-nix worker";

    masterUrl = lib.mkOption {
      type = lib.types.str;
      default = "tcp:host=localhost:port=9989";
      description = "buildbot master url";
    };
  };

  config = lib.mkIf cfg.enable {
    services.buildbot-nix.worker = {
      enable = true;
      inherit (cfg) masterUrl;
      workerPasswordFile = config.clan.core.vars.generators.buildbot-master.files."worker-password".path;
    };
  };
}
