{
  flake.modules.nixos.homepage =
    {
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "home";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8082;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      # the repo logo as favicon and as the installed app's icons, served next
      # to homepage; app icons need png. a path literal copies only this file
      icons = pkgs.runCommand "homepage-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
        mkdir $out
        cp ${../../../../docs/logo/logo.svg} $out/favicon.svg
        rsvg-convert -w 192 -h 192 $out/favicon.svg -o $out/icon-192.png
        rsvg-convert -w 512 -h 512 $out/favicon.svg -o $out/icon-512.png
      '';
    in
    {
      # upstream services is a list of groups; list-merge concatenates, so two
      # modules contributing the same group name produce duplicate headers
      # (gethomepage's yaml path does not dedup, unlike its docker/k8s paths).
      # apply collapses same-named groups at read-time, concatenating their
      # service lists. runs only here (the homepage host reads the option for
      # services.yaml generation); no recursion since apply transforms the
      # already-merged value.
      #
      # modules keep declaring fine-grained groups (media, network, ...); the
      # dashboard shows audience sections instead, so groups are folded into
      # sections here and a few tiles are re-homed by name. sections not in
      # the map keep their group name (tools, monitoring, arr-stack). tiles
      # are sorted case-insensitively within a section.
      #
      # descriptions are search keywords for quicklaunch (searchDescriptions in
      # dashboard.nix); the tile css hides them. a module's own description wins.
      options.services.homepage-dashboard.services = lib.mkOption {
        apply =
          groups:
          let
            sectionOf = {
              media = "apps";
              files = "apps";
              communication = "apps";
              infrastructure = "admin";
              network = "admin";
              code = "admin";
              security = "admin";
              llm = "admin";
            };
            tileSection = {
              "Vaultwarden" = "apps";
              "llama.cpp" = "tools";
              "Buzz" = "admin";
              "Continuwuity" = "admin";
              "Garage" = "management";
              "NetBird" = "management";
              "Authelia" = "management";
              "LLDAP" = "management";
              "Nixbot" = "management";
              "Radicle" = "management";
            };
            descriptions = {
              "AdGuard Home" = "dns, ad blocking";
              "Audiobookshelf" = "audiobooks, podcasts";
              "Authelia" = "sso, login, 2fa";
              "Bazarr" = "subtitles";
              "BentoPDF" = "pdf tools, merge, split";
              "Beszel" = "machine metrics, monitoring";
              "Chaptarr" = "books, ebooks";
              "Continuwuity" = "matrix server";
              "ConvertX" = "file converter";
              "Dawarich" = "location history, gps";
              "DroppedNeedle" = "music";
              "Element" = "matrix chat";
              "fosskar's bliki" = "blog, wiki, notes";
              "Garage" = "s3 object storage";
              "Gatus" = "uptime, health checks";
              "Grafana" = "dashboards, metrics";
              "Home Assistant" = "smart home";
              "HP Printer" = "print, scan";
              "Immich" = "photos, videos";
              "IT Tools" = "developer utilities";
              "Jellyfin" = "movies, series, media";
              "JetKVM HA" = "kvm, remote console";
              "JetKVM nixworker" = "kvm, remote console";
              "Kanidm" = "identity, accounts";
              "Kiwix" = "offline wikipedia";
              "Laya" = "llm";
              "Lidarr" = "music downloads";
              "llama.cpp" = "llm, ai chat";
              "LLDAP" = "ldap, users";
              "MicroBin" = "pastebin, share files";
              "Miniflux" = "rss, feeds, news";
              "Navidrome" = "music streaming";
              "NetBird" = "vpn, mesh";
              "Nixbot" = "ci, nix builds";
              "Nixbox BMC" = "ipmi, remote console";
              "OpenCloud" = "files, cloud storage";
              "OpenWrt AP" = "wifi, access point";
              "OpenWrt Router" = "router, network";
              "PdfCraft" = "pdf editor";
              "PhotoCraft" = "photo editor";
              "Prowlarr" = "indexers";
              "Radarr" = "movie downloads";
              "Radicle" = "git, code";
              "SABnzbd" = "usenet downloads";
              "SearXNG" = "web search";
              "Seerr" = "media requests";
              "Sonarr" = "series downloads";
              "TRMNL" = "e-ink display";
              "VectorCraft" = "vector graphics";
              "Vaultwarden" = "passwords, bitwarden";
              "VictoriaMetrics" = "metrics database";
            };
            describe =
              tile:
              lib.mapAttrs (
                name: attrs:
                attrs
                // lib.optionalAttrs (!(attrs ? description) && descriptions ? ${name}) {
                  description = descriptions.${name};
                }
              ) tile;
            placed = lib.concatMap (
              g:
              lib.concatMap (
                name:
                map (tile: {
                  section = tileSection.${lib.head (lib.attrNames tile)} or sectionOf.${name} or name;
                  tile = describe tile;
                }) g.${name}
              ) (lib.attrNames g)
            ) groups;
            names = lib.unique (map (p: p.section) placed);
            tileName = tile: lib.toLower (lib.head (lib.attrNames tile));
            sorted = tiles: lib.sort (a: b: tileName a < tileName b) tiles;
          in
          map (n: { ${n} = sorted (map (p: p.tile) (lib.filter (p: p.section == n) placed)); }) names;
      };

      config.services.homepage-dashboard = {
        enable = true;
        inherit listenPort;
        openFirewall = false;
        allowedHosts = localHost;

        settings = {
          title = "home-lab dashboard";
          favicon = "/favicon.svg";
          startUrl = "https://${localHost}";
          # a failing widget api would drop an error box into the tile grid
          hideErrors = true;
          # the installed app: its icon, and shortcuts that open a tab directly
          pwa = {
            icons = [
              {
                src = "/icon-192.png";
                type = "image/png";
                sizes = "192x192";
              }
              {
                src = "/icon-512.png";
                type = "image/png";
                sizes = "512x512";
              }
            ];
            shortcuts = [
              {
                name = "Apps";
                url = "/#apps";
              }
              {
                name = "Admin";
                url = "/#admin";
              }
              {
                name = "Machines";
                url = "/#machines";
              }
            ];
          };
          # customCSS (dashboard.nix) is dark-only glass; pin theme so the switcher can't break it
          theme = "dark";
          color = "slate";
          headerStyle = "clean";
          useEqualHeights = true;
          iconStyle = "theme";
          hideVersion = true;
          disableUpdateCheck = true;
          disableIndexing = true;
          statusStyle = "dot";
          cardBlur = "lg";
        };

        customJS = "";
      };

      # the next.js standalone server binds HOSTNAME, else 0.0.0.0
      config.systemd.services.homepage-dashboard.environment.HOSTNAME = listenAddress;

      config.services.caddy.virtualHosts.${localHost}.extraConfig = ''
        # GHSA-qxcr-4rv3-v23r: next.js skips homepage's middleware for requests
        # with this header; homepage 2.6.0 fixes it, nixpkgs ships 2.4.0
        request_header -x-prerender-revalidate

        @icons path /favicon.svg /icon-192.png /icon-512.png
        handle @icons {
          root * ${icons}
          file_server
        }
        reverse_proxy ${listenUrl}
      '';
    };
}
