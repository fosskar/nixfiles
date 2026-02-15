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
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "backend host to proxy to";
      };
      websockets = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable websocket proxying";
      };
      proxy-auth = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "protect with authelia forward-auth";
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "extra nginx config for this vhost";
      };
    };
  };

  # authelia forward-auth snippet for protected locations
  autheliaAuthSnippet = ''
    auth_request /authelia;
    auth_request_set $target_url $scheme://$http_host$request_uri;
    auth_request_set $user $upstream_http_remote_user;
    auth_request_set $groups $upstream_http_remote_groups;
    auth_request_set $name $upstream_http_remote_name;
    auth_request_set $email $upstream_http_remote_email;
    proxy_set_header Remote-User $user;
    proxy_set_header Remote-Groups $groups;
    proxy_set_header Remote-Name $name;
    proxy_set_header Remote-Email $email;
    error_page 401 =302 https://auth.${acmeDomain}/?rd=$target_url;
  '';
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
          locations = {
            "/" = {
              proxyPass = "http://${vhost.host}:${toString vhost.port}";
              recommendedProxySettings = true;
              proxyWebsockets = vhost.websockets;
              extraConfig = lib.optionalString vhost.proxy-auth autheliaAuthSnippet;
            };
          }
          # expose authelia auth endpoint only for protected vhosts
          // lib.optionalAttrs vhost.proxy-auth {
            "/authelia" = {
              proxyPass = "http://127.0.0.1:9091/api/authz/auth-request";
              extraConfig = ''
                internal;
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";
                proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
                proxy_set_header X-Original-Method $request_method;
                proxy_set_header X-Forwarded-Method $request_method;
                proxy_set_header X-Forwarded-For $remote_addr;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host $http_host;
                proxy_set_header X-Forwarded-Uri $request_uri;
              '';
            };
          };
        };
      }) cfg.vhosts;
    };
  };
}
