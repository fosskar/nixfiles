{
  flake.modules.nixos.technitium =
    # filtering recursive resolver for netbird peers. technitium keeps its
    # config in binary files under the state dir and reads DNS_SERVER_* env
    # only on first start, so settings are pushed through the http api after
    # every start instead.
    {
      config,
      lib,
      pkgs,
      flake-self,
      ...
    }:
    let
      dnsPort = 5335;
      webPort = 5380;
      api = "http://127.0.0.1:${toString webPort}/api";
      netbirdHost = "gateway.nb.${flake-self.domains.public}";
      settings = {
        dnsServerDomain = netbirdHost;
        # netbird owns wt0:53 and resolved owns 127.0.0.53, hence the own port;
        # nothing opens it in the firewall, so only wt0 (trusted) reaches it
        dnsServerLocalEndPoints = "0.0.0.0:${toString dnsPort},[::]:${toString dnsPort}";
        webServiceLocalAddresses = "0.0.0.0,[::]";
        webServiceHttpPort = toString webPort;
        dnsServerEnableCheckForUpdate = "false";
        recursion = "UseSpecifiedNetworkACL";
        recursionNetworkACL = "100.116.0.0/16,127.0.0.0/8,::1";
        forwarders = "false";
        dnssecValidation = "true";
        enableBlocking = "true";
        blockingType = "NxDomain";
        blockListUpdateIntervalHours = "24";
        # same lists as the home router (openwrt/devices/router/files/adguardhome.yaml);
        # a leading ! marks an allow list
        blockListUrls = lib.concatStringsSep "," [
          "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.medium.txt"
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt"
          "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/doh.txt"
          "!https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt"
        ];
        logQueries = "false";
        maxStatFileDays = "365";
      };
      settingsArgs = lib.concatMapStringsSep " " (
        name: "--data-urlencode ${lib.escapeShellArg "${name}=${settings.${name}}"}"
      ) (lib.attrNames settings);
    in
    {
      config = {
        services.technitium-dns-server.enable = true;

        clan.core.vars.generators.technitium = {
          files."admin-password" = { };
          runtimeInputs = [ pkgs.pwgen ];
          script = ''
            pwgen -s 48 1 | tr -d '\n' > "$out/admin-password"
          '';
        };

        # first start: technitium seeds the admin password from this file, so the
        # stock admin/admin login never exists on this host
        systemd.services.technitium-dns-server = {
          environment.DNS_SERVER_ADMIN_PASSWORD_FILE = "%d/admin-password";
          serviceConfig.LoadCredential = [
            "admin-password:${config.clan.core.vars.generators.technitium.files."admin-password".path}"
          ];
        };

        systemd.services.technitium-configure = {
          description = "apply declared technitium settings through its api";
          after = [ "technitium-dns-server.service" ];
          requires = [ "technitium-dns-server.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [
            pkgs.curl
            pkgs.jq
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            DynamicUser = true;
            LoadCredential = [
              "admin-password:${config.clan.core.vars.generators.technitium.files."admin-password".path}"
            ];
          };
          script = ''
            set -euo pipefail
            password=$(cat "$CREDENTIALS_DIRECTORY/admin-password")

            for _ in $(seq 1 60); do
              if curl -sf -o /dev/null "http://127.0.0.1:${toString webPort}/"; then
                break
              fi
              sleep 1
            done

            login() {
              curl -sf --data-urlencode user=admin --data-urlencode "pass=$1" "${api}/user/login" \
                | jq -r 'select(.status == "ok") | .token'
            }

            token=$(login "$password")
            if [ -z "$token" ]; then
              token=$(login admin)
              if [ -z "$token" ]; then
                echo "cannot log in with the declared or the default admin password" >&2
                exit 1
              fi
              curl -sf -H "Authorization: Bearer $token" \
                --data-urlencode pass=admin --data-urlencode "newPass=$password" \
                "${api}/user/changePassword" | jq -e '.status == "ok"' >/dev/null
              echo "admin password set from clan vars"
            fi

            curl -sf -H "Authorization: Bearer $token" ${settingsArgs} "${api}/settings/set" \
              | jq -e '.status == "ok"' >/dev/null
            curl -sf -o /dev/null -H "Authorization: Bearer $token" "${api}/user/logout"
          '';
        };

        # --- homepage ---
        services.homepage-dashboard.services = [
          {
            "network" = [
              {
                "Technitium DNS" = {
                  href = "http://${netbirdHost}:${toString webPort}";
                  icon = "technitium.svg";
                  siteMonitor = "http://${netbirdHost}:${toString webPort}";
                };
              }
            ];
          }
        ];

        # --- gatus ---
        services.gatus.settings.endpoints = [
          {
            name = "Technitium DNS";
            url = "tcp://${netbirdHost}:${toString dnsPort}";
            conditions = [ "[CONNECTED] == true" ];
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
          }
        ];

        # DynamicUser service: state lives in /var/lib/private/technitium-dns-server,
        # covered by host-level /var/lib preservation.
      };
    };
}
