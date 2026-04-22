{
  flake.modules.nixos.remoteBuilderClient =
    { config, lib, ... }:
    {
      options.nixfiles.remoteBuilderClient = {
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

      config =
        let
          cfg = config.nixfiles.remoteBuilderClient;
        in
        {
          nix.distributedBuilds = true;
          nix.buildMachines = [
            (
              {
                hostName = cfg.builderHost;
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
              // lib.optionalAttrs (cfg.sshKeyFile != null) {
                sshKey = cfg.sshKeyFile;
              }
            )
          ];
        };
    };

  flake.modules.nixos.remoteBuilderServer =
    { lib, ... }:
    {
      nix.settings.max-jobs = lib.mkDefault 16;
      nix.settings.cores = lib.mkDefault 0;
    };
}
