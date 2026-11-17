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
      counterPort = 8088;
      localHost = "fosskar.${flake-self.domains.local}";
      statsHost = "stats.${flake-self.domains.local}";
      publicHost = "simon.${flake-self.domains.public}";
    in
    {
      services.caddy.virtualHosts = {
        ${localHost}.extraConfig = ''
          reverse_proxy 127.0.0.1:${toString sitePort}
        '';

        # the goatcounter dashboard; lan only
        ${statsHost}.extraConfig = ''
          reverse_proxy 127.0.0.1:${toString counterPort}
        '';

        # what anubis serves: the site, plus goatcounter's count endpoint under
        # the site's own domain, so counting needs no public mapping of its own.
        # no host in the address: anubis passes the public host name through
        "http://:${toString frontPort}" = {
          logFormat = "output file ${config.services.caddy.logDir}/access-website.log";
          extraConfig = ''
            bind 127.0.0.1
            @count path /count /count.js
            handle @count {
              reverse_proxy 127.0.0.1:${toString counterPort} {
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

      services.goatcounter = {
        enable = true;
        address = "127.0.0.1";
        port = counterPort;
        proxy = true;
        extraArgs = [ "-automigrate" ];
      };

      clan.core.vars.generators.goatcounter = {
        files."password" = { };
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          pwgen -s 32 1 | tr -d '\n' > "$out/password"
        '';
      };

      # first start: create the one site and its login. with a single site
      # goatcounter answers on every host name, so the vhost is only a label
      systemd.services.goatcounter.serviceConfig = {
        LoadCredential = [
          "password:${config.clan.core.vars.generators.goatcounter.files."password".path}"
        ];
        ExecStartPre = pkgs.writeShellScript "goatcounter-create-site" ''
          [ -e goatcounter-data/db.sqlite3 ] && exit 0
          ${lib.getExe config.services.goatcounter.package} db create site -createdb \
            -vhost ${statsHost} \
            -user.email simon@${flake-self.domains.local} \
            -password "$(cat "$CREDENTIALS_DIRECTORY/password")"
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
              "GoatCounter" = {
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
        # bliki stays until its netbird mapping is removed
        REDIRECT_DOMAINS = "${publicHost},bliki.${flake-self.domains.public}";
        OG_PASSTHROUGH = true;
      };
    };
}
