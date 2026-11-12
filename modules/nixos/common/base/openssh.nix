{
  flake.modules.nixos.base =
    { lib, self, ... }:
    let
      # login sources that are clan machines; netbird assigns peer ips at runtime, so
      # netbird logins stay unknown
      knownSources = [
        "127.0.0.1"
        "::1"
      ]
      ++ lib.concatMap lib.attrValues (lib.attrValues self.hosts)
      ++ lib.attrValues self.router
      ++ lib.concatMap (
        machine:
        lib.optional (
          machine.config.clan.core.vars.generators ? yggdrasil
        ) machine.config.clan.core.vars.generators.yggdrasil.files.address.value
      ) (lib.attrValues self.nixosConfigurations);

      logRule =
        {
          uid,
          title,
          expr,
          summary,
          description,
        }:
        {
          inherit uid title;
          condition = "C";
          data = [
            {
              refId = "A";
              queryType = "statsRange";
              relativeTimeRange = {
                from = 900;
                to = 0;
              };
              datasourceUid = "PD775F2863313E6C7";
              model = {
                datasource = {
                  type = "victoriametrics-logs-datasource";
                  uid = "PD775F2863313E6C7";
                };
                editorMode = "code";
                inherit expr;
                intervalMs = 1000;
                legendFormat = "{{_HOSTNAME}}";
                maxDataPoints = 43200;
                queryType = "statsRange";
                refId = "A";
              };
            }
            {
              refId = "B";
              relativeTimeRange = {
                from = 0;
                to = 0;
              };
              datasourceUid = "__expr__";
              model = {
                datasource = {
                  type = "__expr__";
                  uid = "__expr__";
                };
                expression = "A";
                intervalMs = 1000;
                maxDataPoints = 43200;
                reducer = "last";
                refId = "B";
                settings.mode = "dropNN";
                type = "reduce";
              };
            }
            {
              refId = "C";
              relativeTimeRange = {
                from = 0;
                to = 0;
              };
              datasourceUid = "__expr__";
              model = {
                conditions = [
                  {
                    evaluator = {
                      params = [ 0 ];
                      type = "gt";
                    };
                    operator.type = "and";
                    query.params = [ ];
                    reducer = {
                      params = [ ];
                      type = "last";
                    };
                    type = "query";
                  }
                ];
                datasource = {
                  type = "__expr__";
                  uid = "__expr__";
                };
                expression = "B";
                intervalMs = 1000;
                maxDataPoints = 43200;
                refId = "C";
                type = "threshold";
              };
            }
          ];
          noDataState = "OK";
          execErrState = "Alerting";
          annotations = { inherit summary description; };
          isPaused = false;
          notification_settings.receiver = "matrix-alert-hook";
        };
    in
    {
      services.openssh = {
        enable = true;
        openFirewall = lib.mkDefault true;
        # socket activation - srvos doesn't set this
        startWhenNeeded = lib.mkDefault true;

        # mirrors srvos common/openssh.nix so we don't depend on it staying there
        settings = {
          X11Forwarding = false;
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
          UseDns = false;
          # unbind gnupg sockets if they exist
          StreamLocalBindUnlink = true;
          # opt in per user with a Match block (workspace host, hermes tunnel)
          AllowAgentForwarding = lib.mkDefault false;
          AllowTcpForwarding = lib.mkDefault false;
        };
      };

      services.grafana.provision.alerting.rules.settings.groups = [
        {
          orgId = 1;
          name = "ssh";
          folder = "Security";
          interval = "1m";
          rules = [
            (logRule {
              uid = "168083f0626c4d";
              title = "SSH login from unknown source";
              expr = ''SYSLOG_IDENTIFIER:="sshd-session" _msg:"Accepted" | extract "Accepted <method> for <user> from <ip> port" | filter -ip:in(${
                lib.concatMapStringsSep "," builtins.toJSON knownSources
              }) | stats by (_HOSTNAME, user, ip) count() as logins'';
              summary = "ssh login as {{ $labels.user }} from {{ $labels.ip }}";
              description = "sshd accepted a login from an address that is no clan machine, lan host, or router in the nix config.";
            })
            (logRule {
              uid = "608a7b3d50b835";
              title = "SSH invalid user";
              expr = ''SYSLOG_IDENTIFIER:="sshd-session" _msg:"Invalid user" | extract "Invalid user <user> from <ip> port" | stats by (_HOSTNAME, user, ip) count() as attempts'';
              summary = "ssh login attempt as unknown user {{ $labels.user }} from {{ $labels.ip }}";
              description = "sshd rejected a login for a user that does not exist.";
            })
          ];
        }
      ];
    };
}
