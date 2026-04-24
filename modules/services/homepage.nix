{
  flake.modules.nixos.homepage =
    { config, lib, ... }:
    let
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
        listenPort = 8082;
        openFirewall = false;
        allowedHosts = "home.nx3.eu";

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

      config.services.caddy.virtualHosts."home.nx3.eu".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
      '';
    };
}
