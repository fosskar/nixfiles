{
  flake.modules.nixos.buzzRelay =
    { flake-self, ... }:
    let
      publicHost = "buzz.${flake-self.domains.public}";
      # bindAddress port of the buzz instance (inventory/apps.nix); local
      # health probe only, clients use publicHost via netbird-proxy
      listenUrl = "http://127.0.0.1:3010";
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
                siteMonitor = listenUrl;
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
