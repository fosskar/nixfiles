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
      default = "nx3.eu";
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
      prompts."desec_token" = {
        description = "deSEC API token for ACME dns-01 challenge";
        type = "hidden";
        persist = true;
      };
      files."envfile" = { };
      script = ''
        echo "DESEC_TOKEN=$(cat "$prompts/desec_token")" > "$out/envfile"
      '';
    };

    # --- service ---

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/desec@v1.1.0" ];
        hash = "sha256-Udwf/DfrUKGGiJ0hbbO4mgYknoH0/bvc44aNXHeI1BY=";
      };
      inherit (cfg) email;
      globalConfig = ''
        acme_dns desec {
          token {env.DESEC_TOKEN}
        }
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

    # --- firewall ---

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        443 # HTTP/3 (QUIC)
      ];
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
