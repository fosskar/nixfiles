_: {
  _class = "clan.service";
  manifest.name = "beszel";
  manifest.description = "beszel hub + agents with declarative systems config";
  manifest.readme = "dedicated beszel service";

  roles.server = {
    description = "beszel hub server";

    perInstance =
      {
        roles,
        ...
      }:
      {
        nixosModule =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            clientMachines = lib.attrNames (roles.client.machines or { });
            beszelPort = 8090;
            beszelDomain = "beszel.${config.domains.local}";

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
                port = clientSettings.port or 45876;
              in
              {
                name = machine;
                inherit host port;
              }
            ) (lib.sort builtins.lessThan clientMachines);

            beszelConfigYml = (pkgs.formats.yaml { }).generate "beszel-config.yml" {
              systems = beszelClientSystems;
            };

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
              host = "127.0.0.1";
              port = beszelPort;
              environment.APP_URL = "https://${beszelDomain}";
            };

            services.homepage-dashboard.serviceGroups."Monitoring" =
              lib.mkIf config.services.homepage-dashboard.enable
                [
                  {
                    "Beszel" = {
                      href = "https://${beszelDomain}";
                      icon = "beszel.svg";
                      siteMonitor = "http://127.0.0.1:${toString beszelPort}";
                    };
                  }
                ];

            services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
              {
                name = "Beszel";
                url = "https://${beszelDomain}";
                group = "Monitoring";
                enabled = true;
                interval = "5m";
                conditions = [ "[STATUS] == 200" ];
                alerts = [ { type = "ntfy"; } ];
              }
            ];

            services.caddy.virtualHosts.${beszelDomain}.extraConfig = ''
              reverse_proxy 127.0.0.1:${toString beszelPort}
            '';

            system.activationScripts.beszelConfig = lib.stringAfter [ "var" ] ''
              ${pkgs.coreutils}/bin/install -Dm0644 ${beszelConfigYml} ${config.services.beszel.hub.dataDir}/beszel_data/config.yml
            '';

            systemd.services.beszel-hub.restartTriggers = [ beszelConfigYml ];
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
            default = 45876;
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
              extraPath = [
                pkgs.intel-gpu-tools
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
              };
            };

            systemd.services.beszel-agent.serviceConfig = {
              AmbientCapabilities = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
              CapabilityBoundingSet = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
              SupplementaryGroups = [
                "disk"
                "video"
                "render"
              ];
              PrivateDevices = lib.mkForce false;
              PrivateUsers = lib.mkForce false;
              NoNewPrivileges = lib.mkForce false;
              BindReadOnlyPaths = [ "/run/dbus/system_bus_socket" ];
            };
          };
      };
  };
}
