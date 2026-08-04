{ inputs, ... }:
{
  # runtime plumbing only; identity, model, and channels come from the clan
  # service composing this engine with its channel aspects
  flake.modules.nixos.hermesAgent =
    {
      config,
      agentVm ? null,
      agentContainer ? null,
      lib,
      pkgs,
      ...
    }:
    let
      stateDir = config.services.hermes-agent.stateDir;
      # containers have no vsock proxy; the host forward connects over the bridge
      dashboardHost = if agentContainer != null then "0.0.0.0" else "127.0.0.1";
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      networking.firewall.allowedTCPPorts = lib.mkIf (agentContainer != null) [ 9119 ];

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;

        extraPackages = [
          pkgs.agent-browser
          pkgs.local.blogwatcher-cli
          pkgs.chromium
          pkgs.curl
          pkgs.himalaya
        ];

        # upstream's settings type does not resolve mkDefault/mkForce
        # priorities, so these must stay plain values; personas add to
        # settings rather than overriding these
        settings = {
          # local sqlite fact store next to the built-in MEMORY.md, which keeps
          # loading; the only provider with no api-key path and no llm calls
          memory.provider = "holographic";

          # summarise old turns instead of hitting the context wall
          compression.enabled = true;
        };
      };

      # -i, not -H: a login shell resets PATH to hermes' own profile. with the
      # caller's PATH the agent's packages are not found and unreadable /root
      # entries turn "command not found" into EACCES
      environment.shellAliases.hermes = "sudo -iu hermes env NPM_CONFIG_PREFIX=${stateDir}/npm VIRTUAL_ENV=${stateDir}/venv hermes";

      systemd.services.hermes-dashboard = {
        description = "Hermes Agent dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.RequiresMountsFor = [ "/run/agent-secrets" ];
        environment = {
          HOME = stateDir;
          HERMES_HOME = "${stateDir}/.hermes";
          HERMES_MANAGED = "true";
          NPM_CONFIG_PREFIX = "${stateDir}/npm";
          VIRTUAL_ENV = "${stateDir}/venv";
        };
        serviceConfig = {
          User = "hermes";
          Group = "hermes";
          WorkingDirectory = config.services.hermes-agent.workingDirectory;
          LoadCredential = "dashboard-token:/run/agent-secrets/hermes-dashboard-token";
          ExecStart = pkgs.writeShellScript "hermes-dashboard-start" ''
            export HERMES_DASHBOARD_SESSION_TOKEN
            HERMES_DASHBOARD_SESSION_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/dashboard-token")"
            exec ${config.services.hermes-agent.package}/bin/hermes dashboard \
              --no-open --host ${dashboardHost} --port 9119
          '';
          Restart = "always";
          RestartSec = 5;
          UMask = "0007";
        };
      };

      systemd.services.hermes-dashboard-proxy = lib.mkIf (agentVm != null) {
        description = "Hermes dashboard vsock proxy";
        wantedBy = [ "multi-user.target" ];
        after = [ "hermes-dashboard.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat VSOCK-LISTEN:9119,fork TCP:127.0.0.1:9119";
          Restart = "always";
          RestartSec = 5;
          DynamicUser = true;
          CapabilityBoundingSet = "";
          IPAddressAllow = "localhost";
          IPAddressDeny = "any";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_VSOCK"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          UMask = "0077";
        };
      };

      # what upstream's ubuntu container mode exists for: somewhere the agent
      # can pip/npm install at runtime
      systemd.tmpfiles.rules = [
        "d ${stateDir}/venv 0750 hermes hermes - -"
        "d ${stateDir}/npm 0750 hermes hermes - -"
      ];

      systemd.services.hermes-venv = {
        description = "writable pip venv for the agent";
        wantedBy = [ "hermes-agent.service" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "hermes";
          RemainAfterExit = true;
        };
        # the venv symlinks its interpreter from the store; after a python
        # bump the old path is gone and site-packages target the wrong abi,
        # so rebuild instead of repairing in place
        script = ''
          want="$(readlink -f ${pkgs.python3}/bin/python3)"
          have="$(readlink -f ${stateDir}/venv/bin/python 2>/dev/null || true)"
          if [ "$have" != "$want" ]; then
            rm -rf ${stateDir}/venv
            install -d -m 0750 ${stateDir}/venv
            ${pkgs.python3}/bin/python3 -m venv ${stateDir}/venv
          fi
        '';
      };

      users.users.hermes.packages = [
        pkgs.nodejs
        pkgs.python3
      ];

      systemd.services.hermes-agent.environment = {
        NPM_CONFIG_PREFIX = "${stateDir}/npm";
        VIRTUAL_ENV = "${stateDir}/venv";
      };
    };
}
