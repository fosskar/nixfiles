{
  flake.modules.nixos.traefik =
    { pkgs, ... }:
    let
      moduleName = "github.com/PascalMinder/geoblock";
      src = pkgs.local.traefik-plugin-geoblock.src;
    in
    {
      services.traefik.staticConfigOptions.experimental.localPlugins.geoblock = {
        inherit moduleName;
      };
      nixfiles.traefik.localPlugins.${moduleName} = src;

      services.traefik.dynamicConfigOptions.http.middlewares.geoblock.plugin.geoblock = {
        allowLocalRequests = true;
        logLocalRequests = false;
        logAllowedRequests = false;
        logApiRequests = false;
        api = "https://get.geojs.io/v1/ip/country/{ip}";
        ignoreApiTimeout = true;
        cacheSize = 1000;
        ipDatabaseCachePath = "/var/lib/traefik/geoblock-ip-cache.db";
        forceMonthlyUpdate = true;
        allowUnknownCountries = false;
        blackListMode = false;
        countries = [ "DE" ];
        addCountryHeader = true;
      };
    };
}
