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
        default = "192.168.10.210";
        description = "hostname or IP of the remote builder";
      };

      maxJobs = lib.mkOption {
        type = lib.types.int;
        default = 16;
        description = "max parallel jobs on the remote builder";
      };

      speedFactor = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "priority weight for this builder";
      };

      sshKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "path to SSH private key for the builder. if null, uses default SSH agent";
      };
    };

    server = {
      enable = lib.mkEnableOption "act as a nix remote builder for other machines";
    };
  };

  config = lib.mkMerge [
    # client: offload builds to the remote builder
    (lib.mkIf cfg.client.enable {
      nix.distributedBuilds = true;
      nix.buildMachines = [
        (
          {
            hostName = cfg.client.builderHost;
            systems = [ "x86_64-linux" ];
            inherit (cfg.client) maxJobs;
            inherit (cfg.client) speedFactor;
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

    # server: accept remote builds
    (lib.mkIf cfg.server.enable {
      nix.settings.trusted-users = [
        "root"
        "@wheel"
      ];
      nix.settings.max-jobs = lib.mkDefault 16;
      nix.settings.cores = lib.mkDefault 0; # use all cores per build
    })
  ];
}
