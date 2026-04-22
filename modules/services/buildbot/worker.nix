{
  flake.modules.nixos.buildbotWorker =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.nixfiles.buildbotWorker;
    in
    {
      imports = [ inputs.buildbot-nix.nixosModules.buildbot-worker ];

      options.nixfiles.buildbotWorker = {
        masterUrl = lib.mkOption {
          type = lib.types.str;
          default = "tcp:host=localhost:port=9989";
          description = "buildbot master url";
        };

        workerCores = lib.mkOption {
          type = lib.types.int;
          default = 16;
          description = "worker count (keep in sync with master workers.json)";
        };
      };

      config = {
        services.buildbot-nix.worker = {
          enable = true;
          inherit (cfg) masterUrl;
          workers = cfg.workerCores;
          workerPasswordFile = config.clan.core.vars.generators.buildbot-master.files."worker-password".path;
        };

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
    };
}
