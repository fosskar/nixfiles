# kanidm next to authelia: own hostname, no oidc clients yet. persons and
# group membership stay runtime state; only the groups themselves are declared.
{
  flake.modules.nixos.kanidm =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "idm";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      # mesh-reachable for the netbird-proxy peer target; the nixos firewall never sees wt0
      listenAddress = "0.0.0.0";
      listenPort = 8443;
      backupDir = "/var/backup/kanidm";

      secretsPermission = {
        secret = true;
        owner = "kanidm";
        group = "kanidm";
      };
    in
    {
      clan.core.vars.generators.kanidm = {
        files = {
          "admin-password" = secretsPermission;
          "idm-admin-password" = secretsPermission;
          # kanidm refuses plain http; netbird-proxy dials it with skip_tls_verify
          "tls-key" = secretsPermission;
          "tls-chain" = secretsPermission;
        };

        runtimeInputs = [
          pkgs.pwgen
          pkgs.openssl
        ];
        script = ''
          pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"
          pwgen -s 32 1 | tr -d '\n' > "$out/idm-admin-password"

          openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
            -days 3650 \
            -subj "/CN=${publicHost}" \
            -addext "subjectAltName=DNS:${publicHost},DNS:localhost,IP:127.0.0.1" \
            -keyout "$out/tls-key" \
            -out "$out/tls-chain"
        '';
      };

      services.kanidm = {
        server.enable = true;
        package = pkgs.kanidmWithSecretProvisioning_1_11;

        server.settings = {
          # the passkey rp id; renaming it later invalidates every enrolled passkey
          domain = publicHost;
          origin = "https://${publicHost}";
          bindaddress = "${listenAddress}:${toString listenPort}";
          ldapbindaddress = "127.0.0.1:3636";

          tls_chain = config.clan.core.vars.generators.kanidm.files."tls-chain".path;
          tls_key = config.clan.core.vars.generators.kanidm.files."tls-key".path;

          online_backup = {
            path = backupDir;
            schedule = "00 3 * * *";
            versions = 7;
          };
        };

        provision = {
          enable = true;
          autoRemove = true;
          adminPasswordFile = config.clan.core.vars.generators.kanidm.files."admin-password".path;
          idmAdminPasswordFile = config.clan.core.vars.generators.kanidm.files."idm-admin-password".path;

          # mirror the lldap groups behind authelia's "users" and "admins" policies;
          # "admin" is taken by the builtin admin account
          groups = {
            users = {
              members = [ "admins" ];
              overwriteMembers = false;
            };
            admins.overwriteMembers = false;
          };
        };
      };

      services.homepage-dashboard.services = [
        {
          "security" = [
            {
              "Kanidm" = {
                href = "https://${publicHost}";
                icon = "kanidm.svg";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Kanidm";
          url = "https://${publicHost}/status";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      clan.core.state.kanidm.folders = [ backupDir ];
    };
}
