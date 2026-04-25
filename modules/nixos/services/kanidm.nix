{
  flake.modules.nixos.kanidm =
    {
      config,
      domains,
      pkgs,
      ...
    }:
    let
      serviceName = "auth";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8443;
      listenUrl = "https://${listenAddress}:${toString listenPort}";
      acmeCertDir = config.security.acme.certs.${domains.local}.directory;
    in
    {
      clan.core.vars.generators.kanidm = {
        files."admin-password" = {
          secret = true;
          owner = config.systemd.services.kanidm.serviceConfig.User;
          group = config.systemd.services.kanidm.serviceConfig.Group;
        };
        files."idm-admin-password" = {
          secret = true;
          owner = config.systemd.services.kanidm.serviceConfig.User;
          group = config.systemd.services.kanidm.serviceConfig.Group;
        };

        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"
          pwgen -s 32 1 | tr -d '\n' > "$out/idm-admin-password"
        '';
      };

      services.kanidm = {
        enableServer = true;
        package = pkgs.kanidmWithSecretProvisioning_1_8;

        serverSettings = {
          origin = "https://${localHost}";
          domain = domains.local;
          bindaddress = "${listenAddress}:${toString listenPort}";
          ldapbindaddress = "${listenAddress}:3636";

          tls_chain = "${acmeCertDir}/fullchain.pem";
          tls_key = "${acmeCertDir}/key.pem";
        };

        provision = {
          enable = true;
          autoRemove = true;
          adminPasswordFile = config.clan.core.vars.generators.kanidm.files."admin-password".path;
          idmAdminPasswordFile = config.clan.core.vars.generators.kanidm.files."idm-admin-password".path;
        };
      };

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
