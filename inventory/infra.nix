{
  config,
  ...
}:
{
  flake.clan.inventory.instances = {
    garage = {
      module = {
        name = "garage";
        input = "self";
      };
      # cluster-wide; role-level so both nodes agree on the set.
      roles.node.settings.buckets = {
        backup = { };
        # protomaps basemap for grid; served via the s3 web endpoint and
        # exposed publicly through netbird-proxy (peer target :3902).
        maps = {
          website = true;
          aliases = [ "maps.${config.flake.domains.public}" ];
        };
        # nix binary cache objects for niks3; clients read anonymously via
        # the s3 web endpoint (http://nixworker.s:3902).
        niks3-cache = {
          website = true;
          aliases = [ "nixworker.s" ];
        };
      };
      roles.node.machines = {
        "nixbox".settings = {
          capacity = "250G";
          dataPath = "/tank/apps/garage";
          ui.enable = true;
        };
        "nixworker".settings.capacity = "250G";
      };
    };

    remote-builder = {
      module = {
        name = "remote-builder";
        input = "self";
      };
      roles = {
        builder.machines."nixworker".settings.extraClientKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGHwgucKTyUpHllRV4dHnoL5FYgqgzsVfRw9IZTJEid"
        ];
        # service no-ops client config on builder machines
        client.tags = [ "all" ];
      };
    };

    harmonia = {
      module = {
        name = "harmonia";
        input = "self";
      };
      roles = {
        server.machines."nixworker" = { };
        client.tags = [ "all" ];
      };
    };

    niks3 = {
      module = {
        name = "niks3";
        input = "self";
      };
      roles = {
        server.machines."nixworker" = { };
        client.tags = [ "all" ];
      };
    };

    ## wait for 0.10.x to fix oncompatible cachix.
    #ncps = {
    #  module = {
    #    name = "ncps";
    #    input = "clan-core";
    #  };
    #  roles = {
    #    server.machines."nixworker".settings = {
    #      caches = [
    #        "https://cache.nixos.org"
    #        "https://cache.nixos-cuda.org"
    #        "https://nix-community.cachix.org"
    #        "https://nix-gaming.cachix.org"
    #        "https://numtide.cachix.org"
    #        "https://zed.cachix.org"
    #      ];
    #      publicKeys = [
    #        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    #        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    #        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    #        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    #        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    #        "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
    #      ];
    #    };
    #    client.tags = [ "all" ];
    #  };
    #};
  };
}
