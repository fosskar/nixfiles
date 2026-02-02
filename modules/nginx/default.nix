{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.nginx;
  acmeDomain = config.nixfiles.acme.domain;

  vhostModule = lib.types.submodule {
    options = {
      port = lib.mkOption {
        type = lib.types.port;
        description = "backend port to proxy to";
      };
      websockets = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable websocket proxying";
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "extra nginx config for this vhost";
      };
    };
  };
in
{
  options.nixfiles.nginx.vhosts = lib.mkOption {
    type = lib.types.attrsOf vhostModule;
    default = { };
    description = "simplified vhost definitions";
  };

  config = lib.mkIf (cfg.vhosts != { }) {
    services.nginx = {
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      appendHttpConfig = ''
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
      '';

      virtualHosts = {
        # reject requests to unknown subdomains
        "_" = {
          default = true;
          useACMEHost = acmeDomain;
          forceSSL = true;
          locations."/".return = "444";
        };
      }
      // lib.mapAttrs' (name: vhost: {
        name = "${name}.${acmeDomain}";
        value = {
          useACMEHost = acmeDomain;
          forceSSL = true;
          inherit (vhost) extraConfig;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString vhost.port}";
            recommendedProxySettings = true;
            proxyWebsockets = vhost.websockets;
          };
        };
      }) cfg.vhosts;
    };
  };
}
