_: {
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
          homeChannel = "!WzCLw1OzVNBoUFn4KwbW-9EqeKu4qps8d3wOcvXZL0g";
          allowedUsers = [ "@fosskar:fosskar.de" ];
        };

        signal.enable = true;

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
