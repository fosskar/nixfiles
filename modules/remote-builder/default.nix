{ config, lib, ... }:
let
  cfg = config.nixfiles.remote-builder;
in
{
  options.nixfiles.remote-builder = {
    client = {
      enable = lib.mkEnableOption "offload nix builds to a remote builder";

      builderHost = lib.mkOption {
        type = lib.types.str;
        description = "hostname or IP of the remote builder";
      };

      sshKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "path to ssh private key for the builder";
      };
    };

    server.enable = lib.mkEnableOption "act as a nix remote builder for other machines";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.client.enable {
      nix.distributedBuilds = true;
      nix.buildMachines = [
        (
          {
            hostName = cfg.client.builderHost;
            sshUser = "nix";
            systems = [ "x86_64-linux" ];
            maxJobs = 16;
            speedFactor = 10;
            protocol = "ssh-ng";
            supportedFeatures = [
              "nixos-test"
              "big-parallel"
              "kvm"
            ];
          }
          // lib.optionalAttrs (cfg.client.sshKeyFile != null) {
            sshKey = cfg.client.sshKeyFile;
          }
        )
      ];
    })

    (lib.mkIf cfg.server.enable {
      nix.settings.max-jobs = lib.mkDefault 16;
      nix.settings.cores = lib.mkDefault 0;
    })
  ];
}
