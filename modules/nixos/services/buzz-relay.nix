{
  flake.modules.nixos.buzzRelay =
    {
      config,
      flake-self,
      lib,
      ...
    }:
    let
      publicHost = "buzz.${flake-self.domains.public}";
      # bindAddress port of the buzz instance (inventory/apps.nix); local
      # health probe only, clients use publicHost via netbird-proxy. "/" is a
      # nostr endpoint and answers plain GET with 404; /health is the probe
      listenUrl = "http://127.0.0.1:3010";
      healthUrl = "${listenUrl}/health";
    in
    {
      # buzz-flake binds its redis to 127.0.0.1:6380, open to every local
      # process; the 0660 unix socket limits it to the redis-buzz group
      services.redis.servers.buzz = {
        port = lib.mkForce 0;
        bind = lib.mkForce null;
      };
      services.buzz-server.redisUrl = lib.mkForce "redis+unix://${config.services.redis.servers.buzz.unixSocket}";
      users.users.${config.services.buzz-server.user}.extraGroups = [
        config.services.redis.servers.buzz.group
      ];

      # the buzz-flake service creates the database via ensureDatabases but
      # does not register it for clan dump/restore
      clan.core.postgresql.databases.buzz = {
        create.enable = false;
        restore.stopOnRestore = [
          "buzz-relay.service"
          "buzz-pair-relay.service"
          "redis-buzz.service"
        ];
      };

      services.homepage-dashboard.services = [
        {
          communication = [
            {
              Buzz = {
                href = "https://${publicHost}";
                icon = "mdi-forum";
                description = "relay";
                siteMonitor = healthUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Buzz Relay";
          url = "https://${publicHost}/";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
}
