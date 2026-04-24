{
  flake.modules.nixos.homepage =
    {
      config,
      domains,
      lib,
      ...
    }:
    let
      serviceName = "home";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8082;
      listenUrl = "http://${listenAddress}:${toString listenPort}";

      cfg = config.services.homepage-dashboard;
      serviceEntry = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    in
    {
      options.services.homepage-dashboard.serviceGroups = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf serviceEntry);
        default = { };
        description = "homepage services keyed by group, rendered into services.yaml once.";
      };

      config.services.homepage-dashboard = {
        enable = true;
        inherit listenPort;
        openFirewall = false;
        allowedHosts = localHost;

        settings = {
          title = "home-lab dashboard";
          headerStyle = "underlined";
          useEqualheights = true;
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
