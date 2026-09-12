_: {
  flake.modules."clan.service".beszel = {
    manifest.name = "beszel";
    manifest.description = "beszel hub + agents with declarative systems config";
    manifest.readme = builtins.readFile ./README.md;

    roles.server = {
      description = "beszel hub server";

      interface =
        { lib, ... }:
        {
          options.extraSystems = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "system name shown in beszel";
                  };
                  host = lib.mkOption {
                    type = lib.types.str;
                    description = "agent host or address";
                  };
                  port = lib.mkOption {
                    type = lib.types.port;
                    default = 45876;
                    description = "agent listen port";
                  };
                };
              }
            );
            default = [ ];
            description = "agents outside clan; systems missing from config.yml are deleted on hub restart";
          };
        };

      perInstance =
        {
          roles,
          settings,
          ...
        }:
        {
          nixosModule =
            {
              flake-self,
              config,
              lib,
              pkgs,
              ...
            }:
            let
              clientMachines = lib.attrNames (roles.client.machines or { });
              beszelPort = 8090;
              beszelDomain = "beszel.${flake-self.domains.local}";

              beszelClientSystems = map (
                machine:
                let
                  clientSettings = (roles.client.machines.${machine} or { }).settings or { };
                  host =
                    if (clientSettings.host or null) != null then
                      clientSettings.host
                    else if machine == config.networking.hostName then
                      "127.0.0.1"
                    else
                      "${machine}.${config.clan.core.settings.domain}";
                  port = clientSettings.port or 18876;
                in
                {
                  name = machine;
                  inherit host port;
                }
              ) (lib.sort builtins.lessThan clientMachines);

              beszelExtraSystems = map (system: {
                inherit (system) name host port;
              }) settings.extraSystems;

              beszelConfigYml = (pkgs.formats.yaml { }).generate "beszel-config.yml" {
                systems = beszelClientSystems ++ beszelExtraSystems;
              };

              beszelSuperuserEmail = "hub@${beszelDomain}";

              # alerts live only in the pocketbase db and are re-created here so
              # every system has them without clicking through the ui
              beszelDefaultAlerts = [
                {
                  name = "Status";
                  value = 0;
                  min = 2;
                }
                {
                  name = "CPU";
                  value = 90;
                  min = 10;
                }
                {
                  name = "Memory";
                  value = 90;
                  min = 10;
                }
                {
                  name = "Disk";
                  value = 90;
                  min = 10;
                }
              ];

              beszelApi = "http://127.0.0.1:${toString beszelPort}/api";

              beszelSuperuserUpsert = pkgs.writeShellScript "beszel-superuser-upsert" ''
                exec ${config.services.beszel.hub.package}/bin/beszel-hub superuser upsert \
                  ${beszelSuperuserEmail} "$BESZEL_SUPERUSER_PASSWORD"
              '';

              beszelDefaultAlertsScript = pkgs.writeShellScript "beszel-default-alerts" ''
                set -euo pipefail
                export PATH=${
                  lib.makeBinPath [
                    pkgs.curl
                    pkgs.jq
                    pkgs.coreutils
                  ]
                }

                for _ in $(seq 60); do
                  if curl -sf -o /dev/null ${beszelApi}/health; then
                    break
                  fi
                  sleep 1
                done

                token=$(curl -sf -X POST ${beszelApi}/collections/_superusers/auth-with-password \
                  -H 'content-type: application/json' \
                  -d "$(jq -cn --arg i ${beszelSuperuserEmail} --arg p "$BESZEL_SUPERUSER_PASSWORD" \
                    '{identity: $i, password: $p}')" | jq -r .token)

                systems=$(curl -sf -H "Authorization: $token" \
                  '${beszelApi}/collections/systems/records?perPage=500&fields=id,users')
                alerts=$(curl -sf -H "Authorization: $token" \
                  '${beszelApi}/collections/alerts/records?perPage=500&fields=system,user,name')

                jq -cn \
                  --argjson systems "$systems" \
                  --argjson alerts "$alerts" \
                  --argjson defaults '${builtins.toJSON beszelDefaultAlerts}' '
                    ($alerts.items | map("\(.user)|\(.system)|\(.name)")) as $have
                    | [ $systems.items[] as $s
                        | $s.users[]? as $u
                        | $defaults[] as $d
                        | { user: $u, system: $s.id, name: $d.name, value: $d.value, min: $d.min }
                      ]
                    | map(select(("\(.user)|\(.system)|\(.name)") as $k | $have | index($k) | not))
                    | .[]' \
                | while read -r alert; do
                    curl -sf -o /dev/null -X POST ${beszelApi}/collections/alerts/records \
                      -H "Authorization: $token" -H 'content-type: application/json' \
                      -d "$alert"
                  done
              '';

            in
            {
              clan.core.vars.generators.beszel-oidc = {
                files."oauth-client-secret" = { };
                files."oauth-client-secret-hash" = {
                  owner = "authelia-main";
                  group = "authelia-main";
                };
                runtimeInputs = [
                  pkgs.pwgen
                  pkgs.authelia
                ];
                script = ''
                  if [ ! -s "$out/oauth-client-secret" ] || [ ! -s "$out/oauth-client-secret-hash" ]; then
                    secret=$(pwgen -s 64 1)
                    authelia crypto hash generate pbkdf2 --password "$secret" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
                    echo -n "$secret" > "$out/oauth-client-secret"
                  fi
                '';
              };

              clan.core.vars.generators.beszel-hub-superuser = {
                files.env = { };
                runtimeInputs = [ pkgs.pwgen ];
                script = ''
                  printf 'BESZEL_SUPERUSER_PASSWORD=%s\n' "$(pwgen -s 64 1)" > "$out/env"
                '';
              };

              clan.core.state.beszel-hub = {
                folders = [ "/var/backup/beszel-hub" ];
                preBackupScript = ''
                  export PATH=${
                    lib.makeBinPath [
                      pkgs.sqlite
                      pkgs.coreutils
                    ]
                  }
                  mkdir -p /var/backup/beszel-hub
                  sqlite3 /var/lib/beszel-hub/beszel_data/beszel.db ".backup '/var/backup/beszel-hub/beszel.db'"
                  sqlite3 /var/lib/beszel-hub/beszel_data/data.db ".backup '/var/backup/beszel-hub/data.db'"
                  sqlite3 /var/lib/beszel-hub/beszel_data/auxiliary.db ".backup '/var/backup/beszel-hub/auxiliary.db'"
                '';
              };

              services.authelia.instances.main.settings.identity_providers.oidc.clients = [
                {
                  client_id = "beszel";
                  client_name = "Beszel";
                  client_secret = "{{ secret \"${
                    config.clan.core.vars.generators.beszel-oidc.files."oauth-client-secret-hash".path
                  }\" }}";
                  public = false;
                  consent_mode = "implicit";
                  authorization_policy = "admins";
                  require_pkce = true;
                  pkce_challenge_method = "S256";
                  redirect_uris = [ "https://${beszelDomain}/api/oauth2-redirect" ];
                  scopes = [
                    "openid"
                    "email"
                    "profile"
                  ];
                  response_types = [ "code" ];
                  grant_types = [ "authorization_code" ];
                  access_token_signed_response_alg = "none";
                  userinfo_signed_response_alg = "none";
                  token_endpoint_auth_method = "client_secret_basic";
                }
              ];

              services.beszel.hub = {
                enable = true;
                package = pkgs.local.beszel;
                host = "127.0.0.1";
                port = beszelPort;
                environment.APP_URL = "https://${beszelDomain}";
                environmentFile = config.clan.core.vars.generators.beszel-hub-superuser.files.env.path;
              };

              systemd.services.beszel-default-alerts = {
                description = "Create default beszel alerts for systems missing them";
                wantedBy = [ "multi-user.target" ];
                after = [ "beszel-hub.service" ];
                requires = [ "beszel-hub.service" ];
                serviceConfig = {
                  Type = "oneshot";
                  DynamicUser = true;
                  EnvironmentFile = config.clan.core.vars.generators.beszel-hub-superuser.files.env.path;
                  ExecStart = beszelDefaultAlertsScript;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectSystem = "strict";
                  NoNewPrivileges = true;
                };
              };

              services.homepage-dashboard.services = [
                {
                  "monitoring" = [
                    {
                      "Beszel" = {
                        href = "https://${beszelDomain}";
                        icon = "beszel.svg";
                        siteMonitor = "http://127.0.0.1:${toString beszelPort}";
                      };
                    }
                  ];
                }
              ];

              services.gatus.settings.endpoints = [
                {
                  name = "Beszel";
                  url = "https://${beszelDomain}";
                  enabled = true;
                  interval = "5m";
                  conditions = [ "[STATUS] == 200" ];
                  alerts = [ { type = "email"; } ];
                }
              ];

              services.caddy.virtualHosts.${beszelDomain}.extraConfig = ''
                reverse_proxy 127.0.0.1:${toString beszelPort}
              '';

              systemd.services.beszel-hub = {
                restartTriggers = [ beszelConfigYml ];
                serviceConfig.ExecStartPre = [
                  "${pkgs.coreutils}/bin/install -Dm0644 ${beszelConfigYml} ${config.services.beszel.hub.dataDir}/beszel_data/config.yml"
                  beszelSuperuserUpsert
                ];
              };
            };
        };
    };

    roles.client = {
      description = "beszel agent";

      interface =
        { lib, ... }:
        {
          options = {
            host = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "override host used in hub config.yml";
            };

            port = lib.mkOption {
              type = lib.types.port;
              # below net.ipv4.ip_local_port_range (32768-65535): beszel's default
              # 45876 sits inside the ephemeral range and gets stolen as an
              # outbound source port before the agent can bind it.
              default = 18876;
              description = "beszel agent listen port";
            };

            sensors = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "sensors to exclude (prefix with -)";
              example = "-nct6798_cputin,-nct6798_auxtin0";
            };

            filesystem = lib.mkOption {
              type = lib.types.str;
              default = "/";
              description = "primary filesystem to monitor";
            };

            extraFilesystems = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "extra filesystems (format: /path__Label,/path2__Label2)";
              example = "/nix__Nix,/tank__Tank";
            };

            smartDevices = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "smart devices to pass to beszel agent";
            };
          };
        };

      perInstance =
        {
          settings,
          roles,
          ...
        }:
        let
          serverMachines = builtins.attrNames (roles.server.machines or { });
        in
        {
          nixosModule =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            {
              clan.core.vars.generators.beszel = {
                share = true;
                prompts."ssh-public-key" = {
                  description = "beszel agent ssh public key for hub auth";
                  persist = true;
                };
                files."ssh-public-key".secret = false;
                script = ''
                  cat "$prompts/ssh-public-key" > "$out/ssh-public-key"
                '';
              };

              networking.firewall.interfaces.ygg.allowedTCPPorts = lib.mkIf (
                !(builtins.elem config.networking.hostName serverMachines)
              ) [ settings.port ];

              services.beszel.agent = {
                enable = true;
                package = pkgs.local.beszel;
                extraPath = [
                  pkgs.smartmontools
                ];
                environment = {
                  LISTEN = toString settings.port;
                  FILESYSTEM = settings.filesystem;
                  KEY_FILE = config.clan.core.vars.generators.beszel.files."ssh-public-key".path;
                }
                // lib.optionalAttrs (settings.sensors != "") {
                  SENSORS = settings.sensors;
                }
                // lib.optionalAttrs (settings.extraFilesystems != "") {
                  EXTRA_FILESYSTEMS = settings.extraFilesystems;
                }
                // lib.optionalAttrs (settings.smartDevices != "") {
                  SMART_DEVICES = settings.smartDevices;
                }
                // lib.optionalAttrs config.virtualisation.podman.enable {
                  DOCKER_HOST = "unix:///run/podman/podman.sock";
                };
              };

              systemd.services.beszel-agent.serviceConfig = {
                AmbientCapabilities = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
                CapabilityBoundingSet = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
                SupplementaryGroups = [
                  "disk"
                  "video"
                  "render"
                ]
                ++ lib.optionals config.virtualisation.podman.enable [ "podman" ];
                PrivateDevices = lib.mkForce false;
                PrivateUsers = lib.mkForce false;
                NoNewPrivileges = lib.mkForce false;
                BindReadOnlyPaths = [ "/run/dbus/system_bus_socket" ];
              };
            };
        };
    };
  };
}
