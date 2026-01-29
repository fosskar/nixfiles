{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.vert;
in
{
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
    virtualisation.oci-containers.containers.vert = {
      image = "ghcr.io/vert-sh/vert:latest";
      ports = [ "127.0.0.1:${toString cfg.port}:80" ];
    };

    virtualisation.oci-containers.containers.vertd = lib.mkIf cfg.vertd.enable {
      image = "ghcr.io/vert-sh/vertd:latest";
      ports = [ "127.0.0.1:${toString cfg.vertd.port}:8000" ];
      # gpu passthrough for vaapi
      extraOptions = [
        "--device=/dev/dri/card1"
        "--device=/dev/dri/renderD128"
      ];
    };

    nixfiles.nginx.vhosts.converter.port = cfg.port;
  };
}
