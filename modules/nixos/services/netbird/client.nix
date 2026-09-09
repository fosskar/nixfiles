{
  flake.modules.nixos.netbirdClient =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    {
      config = {
        services.netbird = {
          # enable tray UI only on graphical clients (niri workstations);
          # headless servers don't need it
          ui.enable = lib.mkDefault (lib.attrByPath [ "programs" "niri" "enable" ] false config);
          # nixpkgs patches the daemon and ui socket path but not the ssh client
          package = lib.mkDefault (
            pkgs.netbird.overrideAttrs (prev: {
              postPatch = prev.postPatch + ''
                substituteInPlace client/ssh/client/client.go \
                  --replace-fail 'unix:///var/run/netbird.sock' 'unix:///var/run/netbird/sock'
              '';
            })
          );
          clients.default = {
            name = lib.mkDefault "netbird";
            interface = lib.mkDefault "wt0";
            hardened = lib.mkDefault false;
            port = lib.mkDefault 51820;
            # netbird >=0.66 logs profile-manager warnings without HOME/XDG
            environment = {
              HOME = lib.mkDefault config.services.netbird.clients.default.dir.state;
              XDG_CONFIG_HOME = lib.mkDefault config.services.netbird.clients.default.dir.state;
            };
          };
        };

        systemd.services.netbird.path = [ pkgs.shadow ];
        # upstream preStart only merges config.d into config.json on start
        systemd.services.netbird.restartTriggers = [
          config.environment.etc."netbird/config.d/50-nixos.json".source
        ];
        # upstream nixpkgs pre-start trips SC2034 (NB_* vars set for the daemon env)
        systemd.services.netbird.enableStrictShellChecks = false;

        systemd.services.netbird.serviceConfig =
          lib.mkIf (!config.services.netbird.clients.default.hardened)
            {
              PrivateTmp = true;
              ProtectSystem = "strict";
              ProtectHome = false;
              NoNewPrivileges = false;
              LockPersonality = true;
              RestrictRealtime = true;
              SystemCallArchitectures = "native";
              ReadWritePaths = [
                "/etc/ssh"
                "/home"
                "/var/lib/lastlog"
                config.services.netbird.clients.default.dir.state
                config.services.netbird.clients.default.dir.runtime
              ];
            };

        users.groups = lib.mapAttrs' (
          _name: client:
          lib.nameValuePair client.user.group { members = lib.mkAfter config.users.groups.wheel.members; }
        ) config.services.netbird.clients;

        # the login script already checks NeedsLogin status before acting,
        # so the state.json guard is unnecessary and prevents re-auth on expired sessions
        systemd.services.netbird-login = {
          unitConfig = {
            ConditionPathExists = lib.mkForce [ ];
            StartLimitIntervalSec = 0;
          };
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "10s";
          };
          environment = {
            HOME = config.services.netbird.clients.default.dir.state;
            XDG_CONFIG_HOME = config.services.netbird.clients.default.dir.state;
          };
        };

        # trust netbird interfaces — netbird handles access control
        networking.firewall.trustedInterfaces = lib.mapAttrsToList (
          _name: client: client.interface
        ) config.services.netbird.clients;
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = lib.mapAttrsToList (
          _name: client:
          if client.hardened then
            {
              directory = client.dir.state;
              user = client.user.name;
              group = client.user.group;
            }
          else
            client.dir.state
        ) config.services.netbird.clients;
      };
    };
}
