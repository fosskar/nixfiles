{
  flake.modules.nixos.buzzRelay =
    { flake-self, ... }:
    let
      localHost = "buzz.${flake-self.domains.local}";
      # bindAddress of the buzz instance (inventory/apps.nix)
      listenUrl = "http://127.0.0.1:3010";
    in
    {
      services.homepage-dashboard.services = [
        {
          communication = [
            {
              Buzz = {
                href = "https://${localHost}";
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
          url = "https://${localHost}/";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
