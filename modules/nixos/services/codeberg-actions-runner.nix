{
  flake.modules.nixos.codebergActionsRunner =
    { config, pkgs, ... }:
    let
      runnerConfig = (pkgs.formats.yaml { }).generate "forgejo-runner-config.yaml" {
        log = {
          level = "info";
          job_level = "info";
        };
        runner = {
          capacity = 1;
          timeout = "3h";
          shutdown_timeout = "3h";
          labels = [ "nixworker:host" ];
        };
        cache.enabled = true;
      };
      runnerStart = pkgs.writeShellScript "forgejo-runner-start" ''
        UUID=$(cat "$CREDENTIALS_DIRECTORY/uuid")
        exec ${pkgs.forgejo-runner}/bin/forgejo-runner daemon \
          --url https://codeberg.org \
          --uuid "$UUID" \
          --token-url "file://$CREDENTIALS_DIRECTORY/token" \
          --label nixworker:host \
          --config ${runnerConfig}
      '';
    in
    {
      clan.core.vars.generators.codeberg-actions-runner = {
        prompts.uuid = {
          description = "codeberg actions runner uuid";
          persist = true;
        };
        prompts.token = {
          description = "codeberg actions runner token";
          type = "hidden";
          persist = true;
        };
        files.uuid.secret = true;
        files.token.secret = true;
        script = ''
          cp "$prompts/uuid" "$out/uuid"
          cp "$prompts/token" "$out/token"
        '';
      };

      containers.codeberg-actions-runner = {
        autoStart = true;
        ephemeral = false;
        privateNetwork = false;
        bindMounts = {
          "/run/secrets/codeberg-actions-runner/uuid" = {
            hostPath = config.clan.core.vars.generators.codeberg-actions-runner.files.uuid.path;
            isReadOnly = true;
          };
          "/run/secrets/codeberg-actions-runner/token" = {
            hostPath = config.clan.core.vars.generators.codeberg-actions-runner.files.token.path;
            isReadOnly = true;
          };
        };

        config =
          { pkgs, ... }:
          {
            system.stateVersion = config.system.stateVersion;

            users.users.forgejo-runner = {
              isSystemUser = true;
              group = "forgejo-runner";
              home = "/var/lib/forgejo-runner";
            };
            users.groups.forgejo-runner = { };

            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];

            systemd.services.forgejo-runner = {
              description = "Forgejo Actions Runner";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              path = with pkgs; [
                bash
                coreutils
                curl
                forgejo-runner
                gawk
                git
                gnused
                jq
                nix
                nodejs
                openssh
                wget
              ];
              serviceConfig = {
                LoadCredential = [
                  "uuid:/run/secrets/codeberg-actions-runner/uuid"
                  "token:/run/secrets/codeberg-actions-runner/token"
                ];
                ExecStart = runnerStart;
                Restart = "on-failure";
                RestartSec = 10;
                User = "forgejo-runner";
                Group = "forgejo-runner";
                WorkingDirectory = "/var/lib/forgejo-runner";
                StateDirectory = "forgejo-runner";
                StateDirectoryMode = "0750";
              };
            };
          };
      };
    };
}
