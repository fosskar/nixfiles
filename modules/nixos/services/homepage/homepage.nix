{
  flake.modules.nixos.homepage =
    {
      flake-self,
      lib,
      ...
    }:
    let
      serviceName = "home";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8082;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
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
              "Home Assistant" = "apps";
              "Vaultwarden" = "apps";
              "llama.cpp" = "tools";
              "HP Printer" = "tools";
              "Buzz" = "admin";
              "Continuwuity" = "admin";
              "Garage" = "management";
              "NetBird" = "management";
              "Authelia" = "management";
              "LLDAP" = "management";
              "Nixbot" = "management";
              "Radicle" = "management";
            };
            placed = lib.concatMap (
              g:
              lib.concatMap (
                name:
                map (tile: {
                  section = tileSection.${lib.head (lib.attrNames tile)} or sectionOf.${name} or name;
                  inherit tile;
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
          baseUrl = "https://${localHost}";
          startUrl = "https://${localHost}";
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

      config.services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
