{
  flake.modules.nixos.website =
    {
      config,
      flake-self,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      sitePort = 8086;
      frontPort = 8087;
      statsPort = 8088;
      # liwan's id for this site; the script on the site sends it as data-entity
      entity = "website";
      liwan = lib.getExe pkgs.local.liwan;
      liwanConfig = (pkgs.formats.toml { }).generate "liwan.config.toml" {
        base_url = "https://${statsHost}";
        listen = "127.0.0.1:${toString statsPort}";
        data_dir = "/var/lib/liwan";
      };
      localHost = "fosskar.${flake-self.domains.local}";
      statsHost = "stats.${flake-self.domains.local}";
      publicHost = "simon.${flake-self.domains.public}";
    in
    {
      services.caddy.virtualHosts = {
        ${localHost}.extraConfig = ''
          reverse_proxy 127.0.0.1:${toString sitePort}
        '';

        # the liwan dashboard; lan only
        ${statsHost}.extraConfig = ''
          reverse_proxy 127.0.0.1:${toString statsPort}
        '';

        # what anubis serves: the site, plus liwan's script and event endpoint
        # under the site's own domain, so counting needs no public mapping.
        # no host in the address: anubis passes the public host name through
        "http://:${toString frontPort}" = {
          logFormat = "output file ${config.services.caddy.logDir}/access-website.log";
          extraConfig = ''
            bind 127.0.0.1
            @stats path /script.js /api/event
            handle @stats {
              reverse_proxy 127.0.0.1:${toString statsPort} {
                # caddy replaces X-Forwarded-For from anubis with 127.0.0.1;
                # netbird-proxy puts the visitor's address in X-Real-Ip
                header_up X-Forwarded-For {http.request.header.X-Real-Ip}
              }
            }
            handle {
              reverse_proxy 127.0.0.1:${toString sitePort}
            }
          '';
        };
      };

      services.static-web-server = {
        enable = true;
        listen = "127.0.0.1:${toString sitePort}";
        root = inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      clan.core.vars.generators.liwan = {
        prompts.password = {
          description = "password for the liwan dashboard user simon";
          type = "hidden";
          persist = true;
        };
        files."password" = { };
      };

      systemd.services.liwan = {
        description = "liwan web analytics";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "liwan";
          LoadCredential = [
            "password:${config.clan.core.vars.generators.liwan.files."password".path}"
          ];
          # the clan var is the password: set it on every start. liwan locks
          # its database, so this only works while the server is down
          ExecStartPre = pkgs.writeShellScript "liwan-user" ''
            password=$(cat "$CREDENTIALS_DIRECTORY/password")
            if ${liwan} --config ${liwanConfig} users | grep -q -- "- simon "; then
              ${liwan} --config ${liwanConfig} update-password simon "$password"
            else
              ${liwan} --config ${liwanConfig} add-user --admin true simon "$password"
            fi
          '';
          ExecStart = "${liwan} --config ${liwanConfig}";
          Restart = "on-failure";
        };
      };

      # the entity and its project, through liwan's api; both calls fail with
      # 400 once they exist
      systemd.services.liwan-configure = {
        description = "create the liwan entity and project for the website";
        after = [ "liwan.service" ];
        requires = [ "liwan.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.curl ];
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          RuntimeDirectory = "liwan-configure";
          LoadCredential = [
            "password:${config.clan.core.vars.generators.liwan.files."password".path}"
          ];
        };
        script = ''
          api=http://127.0.0.1:${toString statsPort}/api/dashboard
          jar=$RUNTIME_DIRECTORY/cookies
          json() { curl --silent --show-error --cookie "$jar" --cookie-jar "$jar" \
            --header 'Content-Type: application/json' --retry 10 --retry-connrefused "$@"; }
          ${pkgs.jq}/bin/jq --null-input --rawfile p "$CREDENTIALS_DIRECTORY/password" \
            '{username: "simon", password: $p}' | json --fail --data @- "$api/auth/login" >/dev/null
          json --data '{"id":"${entity}","displayName":"${publicHost}","projects":[]}' "$api/entity"
          json --data '{"displayName":"${publicHost}","visibility":"private","entities":["${entity}"]}' \
            "$api/project/${entity}"
        '';
      };

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "fosskar" = {
                href = "https://${localHost}/";
                icon = "https://${localHost}/icon.png";
                siteMonitor = "https://${localHost}/";
              };
            }
            {
              "Liwan" = {
                href = "https://${statsHost}/";
                icon = "mdi-chart-line";
                siteMonitor = "https://${statsHost}/";
              };
            }
          ];
        }
      ];

      services.anubis.instances.website.settings = {
        TARGET = "http://127.0.0.1:${toString frontPort}";
        BIND = "0.0.0.0:8098";
        BIND_NETWORK = "tcp";
        METRICS_BIND = "127.0.0.1:8099";
        METRICS_BIND_NETWORK = "tcp";
        REDIRECT_DOMAINS = publicHost;
        OG_PASSTHROUGH = true;
      };
    };
}
