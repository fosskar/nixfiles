{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.vert;
  acmeDomain = config.nixfiles.caddy.domain;
  serviceDomain = "converter.${acmeDomain}";
  bindAddress = "127.0.0.1";
  inherit (cfg) port;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  # --- options ---

  options.nixfiles.vert = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8088;
      description = "port for vert frontend";
    };

    vertd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable vertd GPU video backend";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8089;
        description = "port for vertd backend";
      };
    };
  };

  config = {
    # --- service ---

    virtualisation.oci-containers.containers.vert = {
      image = "ghcr.io/vert-sh/vert:latest";
      ports = [ "127.0.0.1:${toString cfg.port}:80" ];
      environment = lib.mkIf cfg.vertd.enable {
        PUB_VERTD_URL = "https://vertd.${acmeDomain}";
      };
    };

    virtualisation.oci-containers.containers.vertd = lib.mkIf cfg.vertd.enable {
      image = "ghcr.io/vert-sh/vertd:latest";
      ports = [ "127.0.0.1:${toString cfg.vertd.port}:24153" ];
      # gpu passthrough for vaapi
      extraOptions = [
        "--device=/dev/dri/card1"
        "--device=/dev/dri/renderD128"
      ];
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Vert";
        category = "Tools";
        icon = "mdi-video-switch";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Vert";
        url = "https://${serviceDomain}";
        group = "Tools";
      }
    ];

    # --- caddy ---

    nixfiles.caddy.vhosts.converter = {
      inherit port;
    };
    nixfiles.caddy.vhosts.vertd = lib.mkIf cfg.vertd.enable { inherit (cfg.vertd) port; };
  };
}
