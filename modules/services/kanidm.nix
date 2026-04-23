{
  flake.modules.nixos.kanidm =
    { config, pkgs, ... }:
    let
      acmeDomain = "nx3.eu";
      serviceDomain = "auth.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8443;
      internalUrl = "https://${bindAddress}:${toString port}";
      acmeCertDir = config.security.acme.certs.${acmeDomain}.directory;
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
          origin = "https://${serviceDomain}";
          domain = acmeDomain;
          bindaddress = "${bindAddress}:${toString port}";
          ldapbindaddress = "${bindAddress}:3636";

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

      services.caddy.virtualHosts.${serviceDomain}.extraConfig = ''
        reverse_proxy ${internalUrl}
      '';
    };
}
