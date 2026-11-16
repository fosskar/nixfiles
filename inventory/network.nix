{
  config,
  ...
}:
{
  flake.clan.inventory.instances = {
    wifi = {
      module = {
        name = "wifi";
        input = "clan-core";
      };
      roles.default = {
        tags = [ "laptop" ];
        settings.networks = {
          home = { };
        };
      };
    };

    internet = {
      roles.default.machines = builtins.mapAttrs (_: host: {
        settings.host = host.wan or host.lan;
      }) config.flake.hosts;
    };

    yggdrasil = {
      roles.default = {
        tags = [ "all" ];
        # clan-core sets the yggdrasil 0.3 name AllowedEncryptionPublicKeys, which
        # 0.5 ignores, so inbound peering is open to any key. drop once
        # https://git.clan.lol/clan/clan-core/issues/8144 is fixed; eval fails then
        extraModules = [
          (
            { config, ... }:
            {
              services.yggdrasil.settings.AllowedPublicKeys =
                config.services.yggdrasil.settings.AllowedEncryptionPublicKeys;
            }
          )
        ];
      };
      # no lan peers on a hetzner vps; peering uses the static peers
      roles.default.machines."gateway".settings.multicastInterfaces = [ ];
      # the default ".*" also beacons onto the fencr vm bridges, which fails with EPERM
      roles.default.machines."nixworker".settings.multicastInterfaces = [
        {
          Regex = "enp5s0f0np0";
          Beacon = true;
          Listen = true;
          Port = 5400;
        }
      ];
    };

    netbird = {
      module.name = "netbird";
      module.input = "self";

      roles.server.machines."gateway".settings = {
        domain = "nb.${config.flake.domains.public}";
        proxyDomain = "proxy.${config.flake.domains.public}";
        port = 51821;
      };
      roles.client = {
        tags = [ "all" ];
        # routing peers for the home lan
        machines."nixbox".settings.routingFeatures = "server";
        machines."nixworker".settings.routingFeatures = "server";
      };
    };

    tor = {
      roles.server.tags = [ "nixos" ];
    };

    iroh-ssh = {
      module.name = "p2p-ssh-iroh";
      roles.server.tags = [ "all" ];
      # dumbpipe forwards whoever holds the ticket to sshd on loopback, so keep
      # it out of the public repo; only the clan cli reads it
      roles.server.extraModules = [
        (
          { lib, ... }:
          {
            clan.core.vars.generators."p2p-ssh-iroh-iroh-ssh".files.ticket.secret = lib.mkForce true;
          }
        )
      ];
    };

  };
}
