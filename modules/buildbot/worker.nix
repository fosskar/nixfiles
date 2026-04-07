{
  config,
  inputs,
  lib,
  pkgs,
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

    # ssh key for fetching private flake inputs (e.g. nixsecrets) during eval
    clan.core.vars.generators.buildbot-worker-ssh = {
      files."id_ed25519" = {
        owner = "buildbot-worker";
        group = "buildbot-worker";
        mode = "0600";
      };
      files."id_ed25519.pub".secret = false;
      runtimeInputs = [ pkgs.openssh ];
      script = ''
        ssh-keygen -t ed25519 -N "" -C buildbot-worker -f "$out/id_ed25519"
      '';
    };

    systemd.tmpfiles.settings."10-buildbot-worker-ssh" = {
      "/var/lib/buildbot-worker/.ssh".d = {
        user = "buildbot-worker";
        group = "buildbot-worker";
        mode = "0700";
      };
      "/var/lib/buildbot-worker/.ssh/id_ed25519"."L+" = {
        argument = config.clan.core.vars.generators.buildbot-worker-ssh.files."id_ed25519".path;
      };
    };
  };
}
