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
      options.services.homepage-dashboard.services = lib.mkOption {
        apply =
          groups:
          let
            names = lib.unique (lib.concatMap lib.attrNames groups);
          in
          map (n: { ${n} = lib.concatMap (g: g.${n} or [ ]) groups; }) names;
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
          headerStyle = "underlined";
          useEqualHeights = true;
          iconStyle = "theme";
          hideVersion = true;
          disableUpdateCheck = true;
          disableIndexing = true;
          statusStyle = "dot";
          cardBlur = "xl";
        };

        customJS = "";
      };

      config.services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
