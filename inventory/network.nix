{
  config,
  ...
}:
{
  flake.clan.inventory.instances = {
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
      roles.default.tags = [ "all" ];
    };

    netbird = {
      module.name = "netbird";
      module.input = "self";

      roles.server.machines."gateway".settings = {
        domain = "nb.${config.flake.domains.public}";
        proxyDomain = "proxy.${config.flake.domains.public}";
        proxyTCPPorts = [
          8776
          2222
        ];
        port = 51821;
      };
      roles.client = {
        tags = [ "all" ];
        machines."nixbox".settings.routingFeatures = "server";
      };
    };

    tor = {
      roles.server.tags = [ "nixos" ];
    };

    iroh-ssh = {
      module.name = "p2p-ssh-iroh";
      roles.server.tags = [ "all" ];
    };

    #mycelium = {
    #  roles.peer.tags = [ "all" ];
    #};

    #rosenpass = {
    #  module.name = "rosenpass";
    #  module.input = "self";
    #  roles.peer.machines = {
    #    gateway.settings = {
    #      listenPort = 9999;
    #      endpoint = "138.201.155.21:9999";
    #    };
    #    nixbox.settings = { };
    #    desktop.settings = { };
    #    lpt-titan.settings = { };
    #  };
    #};

    # disabled until statelessdns or endpoint exports make this useful.
    # data-mesher = {
    #   module = {
    #     name = "data-mesher";
    #     input = "clan-core";
    #   };
    #   roles.default = {
    #     tags = [ "all" ];
    #     settings = {
    #       interfaces = [
    #         "ygg"
    #         "wireguard"
    #       ];
    #     };
    #   };
    #   roles.bootstrap.machines = {
    #     nixbox = { };
    #     gateway = { };
    #   };
    # };

    # dm-dns = {
    #   module = {
    #     name = "dm-dns";
    #     input = "clan-core";
    #   };
    #   roles.default.tags = [ "all" ];
    #   roles.push.machines = {
    #     nixbox = { };
    #     gateway = { };
    #   };
    # };
  };
}
