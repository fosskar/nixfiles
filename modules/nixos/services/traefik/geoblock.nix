{
  flake.modules.nixos.traefik =
    { config, pkgs, ... }:
    let
      moduleName = "github.com/PascalMinder/geoblock";
      # local plugin pinned by hash instead of a runtime download by tag
      src = pkgs.fetchFromGitHub {
        owner = "PascalMinder";
        repo = "geoblock";
        tag = "v0.3.8";
        hash = "sha256-afooxatN7TomMg0TF7PISHK1VwiZxj1Et825rXprBqU=";
      };
    in
    {
      services.traefik.staticConfigOptions.experimental.localPlugins.geoblock = {
        inherit moduleName;
      };
      systemd.tmpfiles.rules = [
        "L+ ${config.services.traefik.dataDir}/plugins-local/src/${moduleName} - - - - ${src}"
      ];
      # the static config names the module, not the version
      systemd.services.traefik.restartTriggers = [ src ];

      services.traefik.dynamicConfigOptions.http.middlewares.geoblock.plugin.geoblock = {
        allowLocalRequests = true;
        logLocalRequests = false;
        logAllowedRequests = false;
        logApiRequests = false;
        api = "https://get.geojs.io/v1/ip/country/{ip}";
        cacheSize = 1000;
        forceMonthlyUpdate = true;
        allowUnknownCountries = false;
        blackListMode = false;
        countries = [ "DE" ];
        addCountryHeader = true;
      };
    };
}
