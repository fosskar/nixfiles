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
      stampFile = "/run/current-system/source-lastModified";
      cache = "http://nixworker.${config.clan.core.settings.domain}:3902";
      machine = config.clan.core.settings.machine.name;
      vars = config.clan.core.vars.generators.radicle-node;

      # radicle-mirror is a delegate with threshold 1, so a canonical main only
      # proves the mirror signed the ref; the commit signature is what proves
      # the workstation wrote it (users/simon/signing.nix)
      allowedSigners = pkgs.writeText "nixfiles-allowed-signers" ''
        * namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA
      '';

      # ExecCondition: exit 1 skips the run quietly, 255 fails the unit so the
      # failure notification fires. the verified rev is pinned into srcDir so
      # nixos-rebuild cannot pick up a main that moved after verification
      guard = pkgs.writeShellApplication {
        name = "nixos-upgrade-guard";
        runtimeInputs = [
          pkgs.gitMinimal
          pkgs.openssh
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
          if ! git -c safe.directory='*' -c gpg.ssh.allowedSignersFile=${allowedSigners} \
              -C "$storage" verify-commit "$rev" 2>&1; then
            echo "autoupgrade: main $rev is not signed by an allowed key; refusing"
            exit 255
          fi
          remote=$(git -c safe.directory='*' -C "$storage" log -1 --format=%ct "$rev")
          current=$(cat ${stampFile} 2>/dev/null || echo 0)
          if [ "$remote" -le "$current" ]; then
            echo "autoupgrade: main $rev ($remote) is not newer than the running system ($current); skipping"
            exit 1
          fi
          [ -d "$src" ] || git init -q --bare -b main "$src"
          git -c safe.directory='*' -C "$src" fetch -q "$storage" "$rev"
          git -C "$src" update-ref refs/heads/main "$rev"
          out=$(nix eval --raw "git+file://$src?ref=main#nixosConfigurations.${machine}.config.system.build.toplevel.outPath")
          if ! nix path-info --store ${cache} "$out" > /dev/null; then
            echo "autoupgrade: $out for $rev is not in ${cache}; skipping"
            exit 1
          fi
          echo "autoupgrade: main $rev verified and cached; upgrading"
        '';
      };

      # rad-system from the nixpkgs module is only on the system path; the same
      # nsenter into the confined node is needed for the control socket
      seedScript = pkgs.writeShellApplication {
        name = "radicle-seed-nixfiles";
        runtimeInputs = [
          pkgs.util-linux
          config.systemd.package
          config.services.radicle.package
        ];
        text = ''
          exec nsenter -a \
            -t "$(systemctl show -P MainPID radicle-node.service)" \
            -S "$(systemctl show -P UID radicle-node.service)" \
            -G "$(systemctl show -P GID radicle-node.service)" \
            env HOME=${radHome} RAD_HOME=${radHome} \
            rad seed rad:${rid} --scope all
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

        systemd.services.radicle-seed-nixfiles = lib.mkIf cfg.node.enable {
          description = "seed nixfiles on the local radicle node";
          wantedBy = [ "multi-user.target" ];
          after = [ "radicle-node.service" ];
          requires = [ "radicle-node.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.getExe seedScript;
            # the control socket appears a moment after the node's main pid
            Restart = "on-failure";
            RestartSec = 10;
          };
        };

        system.autoUpgrade = {
          enable = true;
          flake = "git+file://${srcDir}?ref=main";
          # after the borg jobs on nixbox (03:00) and gateway (04:00)
          dates = "05:00";
          randomizedDelaySec = "1h";
          allowReboot = false;
        };

        system.systemBuilderCommands = ''
          echo -n ${toString (flake-self.lastModified or 0)} > $out/source-lastModified
        '';

        systemd.services.nixos-upgrade.serviceConfig = {
          ExecCondition = lib.getExe guard;
          StateDirectory = "nixos-upgrade";
        };
      };
    };
}
