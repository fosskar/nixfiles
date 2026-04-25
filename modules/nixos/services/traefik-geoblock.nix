{
  flake.modules.nixos.traefikGeoblock =
    { lib, ... }:
    {
      services.traefik.staticConfigOptions = {
        entryPoints.websecure.http.middlewares = lib.mkAfter [ "geoblock@file" ];
        experimental.plugins.geoblock = {
          moduleName = "github.com/PascalMinder/geoblock";
          version = "v0.3.3";
        };
      };

      services.traefik.dynamicConfigOptions.http.middlewares.geoblock.plugin.geoblock = {
        allowLocalRequests = true;
        logLocalRequests = false;
        logAllowedRequests = false;
        logApiRequests = false;
        api = "https://get.geojs.io/v1/ip/country/{ip}";
        apiTimeoutMs = 750;
        cacheSize = 25;
        forceMonthlyUpdate = true;
        allowUnknownCountries = false;
        blackListMode = false;
        countries = [ "DE" ];
        addCountryHeader = true;
      };
    };
}
