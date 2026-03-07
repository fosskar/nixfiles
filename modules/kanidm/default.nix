{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.kanidm;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "auth.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 8443;
  internalUrl = "https://${bindAddress}:${toString port}";
  acmeCertDir = config.security.acme.certs.${acmeDomain}.directory;
in
{
  # --- options ---

  options.nixfiles.kanidm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "kanidm identity provider";
    };
  };

  config = lib.mkIf cfg.enable {
    # --- secrets ---

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

    # --- service ---

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

    # --- nginx ---

    # https backend requires manual vhost config (can't use nixfiles.nginx.vhosts)
    services.nginx.virtualHosts.${serviceDomain} = {
      useACMEHost = acmeDomain;
      forceSSL = true;
      locations."/" = {
        proxyPass = internalUrl;
        recommendedProxySettings = true;
        proxyWebsockets = true;
      };
    };

    # --- systemd ---

    # kanidm needs acme cert access
    systemd.services.kanidm = {
      after = [ "acme-${acmeDomain}.service" ];
      wants = [ "acme-${acmeDomain}.service" ];
      serviceConfig.SupplementaryGroups = [ config.security.acme.certs.${acmeDomain}.group ];
    };
  };
}
