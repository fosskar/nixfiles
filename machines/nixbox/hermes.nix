{
  config,
  inputs,
  flake-self,
  self,
  lib,
  pkgs,
  ...
}:
let
  names = [
    "hermes"
    "hermina"
  ];
  dashboardNames = lib.filter (name: config.nixfiles.hermes.${name}.dashboard.enable) names;
  generators = config.clan.core.vars.generators;
  hostKey = generators.openssh.files."ssh.id_ed25519";
  forwardLib = import ../../modules/nixos/virtualization/_forwards.nix { inherit lib; };
  guestModule = name: {
    imports = [ config.nixfiles.hermes.${name}.module ];
    services.hermes-agent.dashboardTokenFile = lib.mkIf (lib.elem name dashboardNames) "/run/agent-secrets/hermes-dashboard-token";
    systemd.services = {
      hermes-agent.serviceConfig.EnvironmentFile = "/run/agent-secrets/${name}.env";
      hermes-dashboard = lib.mkIf (lib.elem name dashboardNames) {
        serviceConfig.EnvironmentFile = "/run/agent-secrets/${name}.env";
      };
      # hermes requires loopback with session-token authentication.
      hermes-dashboard-relay = lib.mkIf (lib.elem name dashboardNames) {
        description = "Hermes dashboard on the guest address";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          DynamicUser = true;
          ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:9119,bind=${config.fencr.vms.${name}.ip},fork,reuseaddr TCP:127.0.0.1:9119";
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
  };
in
{
  imports = [ inputs.fencr.nixosModules.fencr ];

  nixfiles.hermes = {
    hermes.providerKeysInEnvironment = false;
    hermina.providerKeysInEnvironment = false;
  };

  fencr.adminKeys = [
    (lib.trim (
      inputs.clan-core.clanLib.getPublicValue {
        flake = config.clan.core.settings.directory;
        machine = config.clan.core.settings.machine.name;
        generator = "openssh";
        file = "ssh.id_ed25519.pub";
      }
    ))
  ];

  fencr.vms = {
    hermes = {
      id = 0;
      services = [
        (guestModule "hermes")
        {
          services.hermes-agent = {
            environment = {
              OPENROUTER_API_KEY = "sk-or-fencr";
              OPENCODE_GO_API_KEY = "sk-or-fencr";
            };
            settings.mcp_servers.nixfiles = {
              url = "https://mcp.fencr/mcp/";
              elicitation = {
                enabled = true;
                timeout = 300;
              };
            };
          };
        }
      ];
      specialArgs = { inherit inputs self flake-self; };
      inbound = [ 9119 ];
      outbound = [
        "internet"
        "host:443"
        "192.168.10.50:8123"
      ];
      credentials = [
        "hermes-openrouter"
        "hermes-opencode_go"
        "mcp-gateway"
      ];
      secrets = {
        "hermes.env" = generators.hermes-agent.files.".env".path;
        "hermes-dashboard-token" = generators.hermes-dashboard.files.token.path;
      };
    };
    hermina = {
      id = 1;
      services = [
        (guestModule "hermina")
        { services.hermes-agent.environment.OPENCODE_GO_API_KEY = "sk-or-fencr"; }
      ];
      specialArgs = { inherit inputs self flake-self; };
      outbound = [
        "internet"
        "host:443"
        "192.168.10.50:8123"
      ];
      credentials = [ "hermina-opencode_go" ];
      secrets = {
        "hermina.env" = generators.hermina-agent.files.".env".path;
      };
    };
  };

  fencr.credentials = {
    hermes-openrouter = {
      upstream = "https://openrouter.ai";
      secretFile = generators.hermes-agent.files.openrouter-authorization.path;
    };
    hermes-opencode_go = {
      upstream = "https://opencode.ai";
      secretFile = generators.hermes-agent.files.opencode_go-authorization.path;
    };
    hermina-opencode_go = {
      upstream = "https://opencode.ai";
      secretFile = generators.hermina-agent.files.opencode_go-authorization.path;
    };
    mcp-gateway = {
      upstream = "http://127.0.0.1:${toString config.services.mcpGateway.port}";
      domain = "mcp.fencr";
      secretFile = generators.mcp-gateway.files.authorization.path;
    };
  };

  systemd.services = lib.listToAttrs (
    map (name: {
      name = "${name}-forward-${toString config.nixfiles.hermes.${name}.dashboardPort}@";
      value = {
        after = [ "fencr-${name}.service" ];
        requisite = [ "fencr-${name}.service" ];
        unitConfig.CollectMode = "inactive-or-failed";
        serviceConfig = forwardLib.hardening config.fencr.vms.${name}.ip // {
          ExecStart = "${pkgs.socat}/bin/socat STDIO TCP:${config.fencr.vms.${name}.ip}:9119";
        };
      };
    }) dashboardNames
  );

  systemd.sockets = lib.listToAttrs (
    map (name: {
      name = "${name}-forward-${toString config.nixfiles.hermes.${name}.dashboardPort}";
      value = {
        wantedBy = [ "sockets.target" ];
        listenStreams = [ "127.0.0.1:${toString config.nixfiles.hermes.${name}.dashboardPort}" ];
        socketConfig = {
          Accept = true;
          MaxConnections = 64;
        };
      };
    }) dashboardNames
  );

  assertions = [
    {
      assertion = lib.allUnique (map (name: config.nixfiles.hermes.${name}.dashboardPort) dashboardNames);
      message = "nixbox: Hermes dashboard ports must be unique.";
    }
  ];

  programs.ssh.extraConfig = lib.mkAfter (
    lib.concatMapStrings (name: ''
      Host ${name}
        IdentityFile ${hostKey.path}
    '') names
  );
  environment.shellAliases = lib.genAttrs names (name: "ssh -t ${name} -- sudo -iu hermes hermes");

  clan.core.state.agent-vms = {
    folders = [ "/var/backup/agent-vms" ];
    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          pkgs.rsync
          pkgs.coreutils
          pkgs.systemd
        ]
      }
      active=""
      for unit in ${lib.concatMapStringsSep " " (name: "fencr-${name}.service") names}; do
        if systemctl is-active --quiet "$unit"; then
          active="$active $unit"
        fi
      done
      restart() {
        if [ -n "$active" ]; then
          systemctl start --no-block $active
        fi
      }
      trap restart EXIT
      if [ -n "$active" ]; then
        systemctl stop $active
      fi
      mkdir -p /var/backup/agent-vms
      rsync -a --delete /var/lib/fencr-vms/ /var/backup/agent-vms/
    '';
  };
}
