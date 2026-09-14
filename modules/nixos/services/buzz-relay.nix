{
  flake.modules.nixos.buzzRelay =
    { flake-self, ... }:
    let
      publicHost = "buzz.${flake-self.domains.public}";
      # bindAddress port of the buzz instance (inventory/apps.nix); local
      # health probe only, clients use publicHost via netbird-proxy. "/" is a
      # nostr endpoint and answers plain GET with 404; /health is the probe
      listenUrl = "http://127.0.0.1:3010";
      healthUrl = "${listenUrl}/health";
    in
    {
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
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
}
