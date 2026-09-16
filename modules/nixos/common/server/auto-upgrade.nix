{
  flake.modules.nixos.server =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.nixfiles.autoUpgrade;
      # nixfiles on radicle, seeded by radicle-mirror on nixworker
      rid = "z4X1gDvBMpZLyzkQEj7dCMpurwqkV";
      seedNode = "z6Mkfs9BG9u9P6mzwH1ioSQiS6TbpXGUHiAWrmVjYtLnzP9G";
      seedAddress = "${seedNode}@seed.${flake-self.domains.public}:8776";
      radHome = "/var/lib/radicle";
      storage = "${cfg.radHome}/storage/${rid}";
      srcDir = "/var/lib/nixos-upgrade/src";
      # mtime of the current generation link: when the running system was
      # deployed, by this timer or by clan. clan evaluates from a path: store
      # copy, so flake-self carries no lastModified to stamp the commit with
      currentGeneration = "/nix/var/nix/profiles/$(readlink /nix/var/nix/profiles/system)";
      cache = "http://nixworker.${config.clan.core.settings.domain}:3902";
      machine = config.clan.core.settings.machine.name;
      vars = config.clan.core.vars.generators.radicle-node;

      # ExecCondition: exit 1 skips the run quietly, 255 fails the unit so the
      # failure notification fires. the rev is pinned into srcDir so
      # nixos-rebuild cannot pick up a main that moved after the check.
      # forward-only: main must be committed after the running generation was
      # deployed, so a manual deploy of newer local work is not reverted.
      # provenance is not checked here: the radicle node validates the
      # delegate sigrefs at fetch time, so a canonical refs/heads/main only
      # exists if radicle-mirror signed it (allowedOwners gates the source)
      guard = pkgs.writeShellApplication {
        name = "nixos-upgrade-guard";
        runtimeInputs = [
          pkgs.gitMinimal
          config.nix.package
          pkgs.coreutils
        ];
        text = ''
          storage=${storage}
          src=${srcDir}
          if ! rev=$(git -c safe.directory='*' -C "$storage" rev-parse --verify -q refs/heads/main); then
            echo "autoupgrade: no canonical main in $storage yet; skipping"
            exit 1
          fi
          remote=$(git -c safe.directory='*' -C "$storage" log -1 --format=%ct "$rev")
          current=$(stat -c %Y "${currentGeneration}")
          if [ "$remote" -le "$current" ]; then
            echo "autoupgrade: main $rev ($remote) predates the running generation ($current); skipping"
            exit 1
          fi
          [ -d "$src" ] || git init -q --bare -b main "$src"
          git -c safe.directory='*' -C "$src" fetch -q "$storage" "$rev"
          git -C "$src" update-ref refs/heads/main "$rev"
          # rev pinned: a bare ref=main would reuse nix's cached ref lookup for
          # up to tarball-ttl and evaluate the previous rev
          out=$(nix eval --raw "git+file://$src?ref=main&rev=$rev#nixosConfigurations.${machine}.config.system.build.toplevel.outPath")
          if [ "$out" = "$(readlink /run/current-system)" ]; then
            echo "autoupgrade: $out is already running; skipping"
            exit 1
          fi
          if ! nix path-info --store ${cache} "$out" > /dev/null; then
            echo "autoupgrade: $out for $rev is not in ${cache}; skipping"
            exit 1
          fi
          echo "autoupgrade: main $rev cached; upgrading"
        '';
      };

    in
    {
      options.nixfiles.autoUpgrade = {
        node.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "run a radicle node on this machine that seeds nixfiles.";
        };
        radHome = lib.mkOption {
          type = lib.types.str;
          default = radHome;
          description = "RAD_HOME whose storage holds the seeded nixfiles repository.";
        };
      };

      config = {
        clan.core.vars.generators.radicle-node = {
          files.key = { };
          files."key.pub".secret = false;
          runtimeInputs = [ pkgs.openssh ];
          script = ''
            ssh-keygen -q -t ed25519 -N "" -C "${machine}" -f "$out/key"
          '';
        };

        services.radicle = lib.mkIf cfg.node.enable {
          enable = true;
          privateKey = vars.files.key.path;
          publicKey = vars.files."key.pub".value;
          # outbound only: the node fetches from the seed and serves nobody.
          # not 8776: on gateway netbird-proxy binds *:8776 for seed.fosskar.eu
          node.listenAddress = "127.0.0.1";
          node.listenPort = 18776;
          settings.node = {
            alias = machine;
            connect = [ seedAddress ];
            seedingPolicy.default = "block";
          };
        };

        # seeding writes the policy database; done before the node opens it,
        # because rad seed against the running node locked the database and
        # the node exited with "database is locked"
        systemd.services.radicle-node = lib.mkIf cfg.node.enable {
          serviceConfig.ExecStartPre = "${lib.getExe' config.services.radicle.package "rad"} seed rad:${rid} --scope all";
        };

        system.autoUpgrade = {
          enable = true;
          flake = "git+file://${srcDir}?ref=main";
          # local time; the servers run UTC. after the borg jobs on nixbox
          # (03:00 UTC) and gateway (04:00 UTC)
          dates = "06:00 Europe/Berlin";
          randomizedDelaySec = "1h";
          allowReboot = false;
        };

        systemd.services.nixos-upgrade.serviceConfig = {
          ExecCondition = lib.getExe guard;
          StateDirectory = "nixos-upgrade";
        };
      };
    };
}
