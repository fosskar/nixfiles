{
  flake.modules.nixos.homepage =
    {
      flake-self,
      config,
      lib,
      ...
    }:
    let
      serviceName = "home";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8082;
      listenUrl = "http://${listenAddress}:${toString listenPort}";

      cfg = config.services.homepage-dashboard;
    in
    {
      # serviceGroups option is declared in base; collected fleet-wide by
      # homepage/collector.nix. here we just render the merged result.
      config.services.homepage-dashboard = {
        enable = true;
        inherit listenPort;
        openFirewall = false;
        allowedHosts = localHost;

        settings = {
          title = "home-lab dashboard";
          baseUrl = "https://${localHost}";
          startUrl = "https://${localHost}";
          headerStyle = "underlined";
          useEqualHeights = true;
          iconStyle = "theme";
          hideVersion = true;
          disableUpdateCheck = true;
          disableIndexing = true;
          statusStyle = "dot";
          cardBlur = "xl";
        };

        customJS = "";

        services = lib.mapAttrsToList (name: services: { ${name} = services; }) cfg.serviceGroups;
      };

      config.services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
