{ self }:
{
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
            beszelDomain = "beszel.${config.nixfiles.caddy.domain}";

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
            imports = [ self.modules.nixos.beszelHub ];

            nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
              {
                name = "Beszel";
                category = "Monitoring";
                icon = "beszel.svg";
                href = "https://${beszelDomain}";
                siteMonitor = "http://127.0.0.1:${toString beszelPort}";
              }
            ];

            nixfiles.gatus.endpoints = lib.mkIf config.services.gatus.enable [
              {
                name = "Beszel";
                url = "https://${beszelDomain}";
                group = "Monitoring";
              }
            ];

            nixfiles.caddy.vhosts.beszel.port = lib.mkDefault beszelPort;

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
            ...
          }:
          {
            imports = [ self.modules.nixos.beszelAgent ];

            networking.firewall.interfaces.ygg.allowedTCPPorts = lib.mkIf (
              !(builtins.elem config.networking.hostName serverMachines)
            ) [ settings.port ];

            nixfiles.beszelAgent.port = lib.mkDefault settings.port;

            services.beszel.agent.environment.KEY_FILE =
              config.clan.core.vars.generators."beszel".files."ssh-public-key".path;
          };
      };
  };
}
