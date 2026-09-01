{ config, ... }:
{
  flake.clan.inventory.instances = {
    # self-hosted buzz relay; media and git data in the local garage cluster
    # (bucket buzz-media, inventory/infra.nix). homepage tile and gatus
    # endpoint live in modules/nixos/services/buzz-relay.nix. public ingress
    # is netbird-proxy on gateway (mapping in the NetBird UI); the relay keys
    # its community by the RELAY_URL host, so all clients use the public url
    buzz = {
      module = {
        name = "buzz";
        input = "buzz-flake";
      };
      roles.server.machines.nixbox.settings = {
        relayUrl = "wss://buzz.${config.flake.domains.public}";
        # default 3000 collides with convertx; netbird-proxy targets this port
        bindAddress = "0.0.0.0:3010";
        pairingRelay = {
          enable = true;
          bindAddress = "0.0.0.0:5000";
        };
        # humans join via invite links; desktop-managed agents authenticate
        # through NIP-OA owner delegation. only the operator and headless
        # agents without a desktop owner attestation need roster entries
        requireRelayMembership = true;
        members = {
          # simon
          "1c9f5bb1b4adb233b8c383c1ee98cf40a90d6194d63bee11e6d332955836e6a2" = "admin";
          # hermes agent
          "c53044e08959d597e548183571c957ff835ff0b4da5886700fca74023ec6fb7e" = "member";
          # ORouter community agent
          "6228c04164cead71dfd9fee39a425ab88d622efb85a825fe13d1ca1886c9ee1b" = "member";
        };
        settings.RELAY_OWNER_PUBKEY = "1c9f5bb1b4adb233b8c383c1ee98cf40a90d6194d63bee11e6d332955836e6a2";
        settings.BUZZ_ALLOW_NIP_OA_AUTH = true;
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
          opencode_go.enable = true;
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
        providers = {
          local.enable = true;
          opencode_go.enable = true;
        };
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
        # desktop disabled: age decrypt retry loop forks ~2000 procs/sec and
        # stalls the scx_lavd watchdog. see fosskar/ssync#109
        # "desktop".settings.user = "simon";
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
