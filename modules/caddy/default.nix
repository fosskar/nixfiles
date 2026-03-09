{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.caddy;

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
        description = "enable websocket proxying (caddy does this by default)";
      };
      proxy-auth = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "protect with authelia forward-auth";
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "extra caddy config for this vhost";
      };
    };
  };

  autheliaForwardAuth = ''
    forward_auth 127.0.0.1:9091 {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }
  '';
in
{
  # --- options ---

  options.nixfiles.caddy = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "osscar.me";
      description = "base domain for vhosts";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "letsencrypt.unpleased904@passmail.net";
      description = "email for ACME registration";
    };
    vhosts = lib.mkOption {
      type = lib.types.attrsOf vhostModule;
      default = { };
      description = "simplified vhost definitions";
    };
  };

  config = lib.mkIf (cfg.vhosts != { }) {
    # --- secrets ---

    clan.core.vars.generators.caddy = {
      prompts."cf_api_token" = {
        description = "cloudflare API token for ACME dns-01 challenge";
        type = "hidden";
        persist = true;
      };
      files."envfile" = { };
      script = ''
        echo "CF_DNS_API_TOKEN=$(cat "$prompts/cf_api_token")" > "$out/envfile"
      '';
    };

    # --- service ---

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
        hash = "sha256-mmkziFzEMBcdnCWCRiT3UyWPNbINbpd3KUJ0NMW632w=";
      };
      inherit (cfg) email;
      globalConfig = ''
        acme_dns cloudflare {env.CF_DNS_API_TOKEN}
      '';
      virtualHosts = lib.mapAttrs' (name: vhost: {
        name = "${name}.${cfg.domain}";
        value = {
          extraConfig = ''
            ${lib.optionalString vhost.proxy-auth autheliaForwardAuth}
            reverse_proxy ${vhost.host}:${toString vhost.port}
            ${vhost.extraConfig}
          '';
        };
      }) cfg.vhosts;
    };

    # --- systemd ---

    systemd.services.caddy.serviceConfig.EnvironmentFile =
      config.clan.core.vars.generators.caddy.files."envfile".path;

    # --- persistence ---

    nixfiles.persistence.directories = [
      {
        directory = "/var/lib/caddy";
        user = "caddy";
        group = "caddy";
      }
    ];
  };
}
