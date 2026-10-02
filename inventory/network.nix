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

    wireguard = {
      module.name = "wireguard";
      module.input = "clan-core";

      roles.controller.machines."gateway".settings = {
        endpoint = config.flake.hosts.gateway.wan;
        port = 51820; # default
      };
      roles.peer.machines = {
        "nixbox".settings = { };
        "desktop".settings = { };
        "lpt-titan".settings = { };
        "nixworker".settings = { };
      };
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
    };

    netbird = {
      module.name = "netbird";
      module.input = "self";

      roles.server.machines."gateway".settings = {
        domain = "nb.${config.flake.domains.public}";
        proxyDomain = "proxy.${config.flake.domains.public}";
        proxyTCPPorts = [ 8776 ];
        port = 51821;
      };
      roles.client = {
        tags = [ "all" ];
        # routing peers: nixbox and nixworker for the home lan, gateway for
        # the exit route (0.0.0.0/0 must not be routed from inside the lan,
        # the route acl has no destination match for a /0)
        machines."nixbox".settings.routingFeatures = "server";
        machines."nixworker".settings.routingFeatures = "server";
        machines."gateway".settings.routingFeatures = "server";
      };
    };

    tor = {
      roles.server.tags = [ "nixos" ];
    };

    iroh-ssh = {
      module.name = "p2p-ssh-iroh";
      roles.server.tags = [ "all" ];
    };

  };
}
