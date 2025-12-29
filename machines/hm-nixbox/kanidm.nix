{
  config,
  pkgs,
  ...
}:
{
  # generate kanidm secrets via clan vars
  clan.core.vars.generators.kanidm = {
    files."admin-password" = {
      secret = true;
      owner = "kanidm";
    };
    files."idm-admin-password" = {
      secret = true;
      owner = "kanidm";
    };
    files."pangolin-client-secret" = {
      secret = true;
      owner = "kanidm";
    };
    files."tls-key" = {
      secret = true;
      owner = "kanidm";
    };
    files."tls-cert" = {
      secret = false;
      owner = "kanidm";
    };

    runtimeInputs = with pkgs; [
      coreutils
      pwgen
      openssl
    ];
    script = ''
      pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"
      pwgen -s 32 1 | tr -d '\n' > "$out/idm-admin-password"
      pwgen -s 64 1 | tr -d '\n' > "$out/pangolin-client-secret"

      # generate self-signed cert for internal tls (traefik -> kanidm)
      openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout "$out/tls-key" \
        -out "$out/tls-cert" \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,DNS:auth.osscar.me,IP:127.0.0.1"
    '';
  };

  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidm.withSecretProvisioning;

    serverSettings = {
      origin = "https://auth.osscar.me";
      domain = "osscar.me";
      bindaddress = "127.0.0.1:8443";
      tls_chain = config.clan.core.vars.generators.kanidm.files."tls-cert".path;
      tls_key = config.clan.core.vars.generators.kanidm.files."tls-key".path;
    };

    provision = {
      enable = true;
      adminPasswordFile = config.clan.core.vars.generators.kanidm.files."admin-password".path;
      idmAdminPasswordFile = config.clan.core.vars.generators.kanidm.files."idm-admin-password".path;

      groups = {
        admin.members = [ "simon" ];
        user.members = [
          "simon"
          "ina"
        ];
      };

      persons = {
        simon = {
          displayName = "Simon";
          mailAddresses = [ "simonsiedl@pm.me" ];
          groups = [
            "admin"
            "user"
          ];
        };
        ina = {
          displayName = "Ina";
          mailAddresses = [ ];
          groups = [ "user" ];
        };
      };

      systems.oauth2.pangolin = {
        displayName = "Pangolin";
        originUrl = "https://pango.osscar.me/auth/idp/1/oidc/callback";
        originLanding = "https://pango.osscar.me";
        basicSecretFile = config.clan.core.vars.generators.kanidm.files."pangolin-client-secret".path;
        preferShortUsername = true;

        # scope maps: which groups get which scopes
        scopeMaps = {
          user = [
            "openid"
            "profile"
            "email"
          ];
          admin = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
        };

        # claim maps for pangolin organization/role mapping
        claimMaps.groups = {
          joinType = "array";
          valuesByGroup = {
            admin = [ "admin" ];
            user = [ "user" ];
          };
        };
      };
    };
  };
}
