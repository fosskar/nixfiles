{ config, ... }:
{
  flake.clan.inventory.instances = {
    # self-hosted buzz relay; media and git data in the local garage cluster
    # (bucket buzz-media, inventory/infra.nix). caddy vhost, homepage tile and
    # gatus endpoint live in modules/nixos/services/buzz-relay.nix.
    buzz = {
      module = {
        name = "buzz";
        input = "buzz-flake";
      };
      roles.server.machines.nixbox.settings = {
        relayUrl = "wss://buzz.${config.flake.domains.local}";
        # default 3000 collides with convertx; buzz-relay.nix proxies this
        bindAddress = "127.0.0.1:3010";
        s3.endpoint = "http://127.0.0.1:3900";
        # garage sets s3_region to the host name
        s3.region = "nixbox";
        # accepted risk: garage has no conditional writes (garage#1052), so
        # the relay's git pointer-CAS startup gate fails. skipping it means
        # buzz-hosted git repos would lose updates silently under concurrent
        # pushes -- do not host repos through buzz; media/chat are unaffected.
        settings.BUZZ_GIT_CONFORMANCE_PROBE = false;
      };
      # desktop app on the workstations, preconfigured with this relay
      roles.client.tags = [ "workstation" ];
    };

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

    hermes = {
      module = {
        name = "hermes";
        input = "self";
      };
      roles.server.machines.nixbox.settings = {
        soul = "tars";
        mcp.enable = true;

        providers = {
          local.enable = true;
          openrouter.enable = true;
        };

        packageSkills = [ "optional-skills/devops/watchers" ];

        matrix = {
          enable = true;
          userId = "@hermes:fosskar.de";
          deviceId = "c14FEq9Hbv";
          homeChannel = "!WzCLw1OzVNBoUFn4KwbW-9EqeKu4qps8d3wOcvXZL0g";
          allowedUsers = [ "@fosskar:fosskar.de" ];
        };

        signal.enable = true;

        buzz = {
          enable = true;
          allowedUsers = [ "1c9f5bb1b4adb233b8c383c1ee98cf40a90d6194d63bee11e6d332955836e6a2" ];
        };

        homeAssistant.enable = true;
      };
      roles.client.tags = [ "workstation" ];
    };

    hermina = {
      module = {
        name = "hermes";
        input = "self";
      };
      roles.server.machines.nixbox.settings = {
        backend = "container";
        id = 1;
        providers.local.enable = true;
        signal.enable = true;
        homeAssistant.enable = true;
      };
    };

    # p2p sync of pi agent sessions between the workstations and the
    # nixworker dev host. leaderless: all machines are equal peers. shared
    # age key handled by the service's own clan.vars generator.
    ssync = {
      module = {
        name = "ssync";
        input = "ssync";
      };
      roles.peer.machines = {
        "desktop".settings.user = "simon";
        "lpt-titan".settings.user = "simon";
        "nixworker".settings.user = "simon";
      };
    };

    #syncthing = {
    #  module = {
    #    name = "syncthing";
    #    input = "clan-core";
    #  };
    #  roles.peer = {
    #    machines."desktop" = { };
    #    machines."lpt-titan" = { };
    #    settings = {
    #      folders = {
    #        # add folders here, e.g.:
    #        documents = {
    #          path = "/home/simon/documents";
    #          type = "sendreceive";
    #        };
    #        #zen-browser = {
    #        #  path = "/home/simon/.zen";
    #        #  type = "sendreceive";
    #        #};
    #      };
    #    };
    #  };
    #};
  };
}
