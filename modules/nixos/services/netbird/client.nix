{
  flake.modules.nixos.netbirdClient =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      hasPreservation = lib.hasAttrByPath [ "preservation" "preserveAt" ] options;
    in
    {
      config = lib.mkMerge [
        {
          services.netbird = {
            ui.enable = lib.mkDefault false;
            package = lib.mkDefault pkgs.custom.netbird-client;
            clients.default = {
              name = lib.mkDefault "netbird";
              interface = lib.mkDefault "wt0";
              hardened = lib.mkDefault true;
              port = lib.mkDefault 51820;
              # netbird >=0.66 logs profile-manager warnings without HOME/XDG
              environment = {
                HOME = lib.mkDefault config.services.netbird.clients.default.dir.state;
                XDG_CONFIG_HOME = lib.mkDefault config.services.netbird.clients.default.dir.state;
              };
            };
          };

          systemd.services.netbird.path = [ pkgs.shadow ];

          users.groups = lib.mapAttrs' (
            _name: client: lib.nameValuePair client.user.group { members = config.users.groups.wheel.members; }
          ) config.services.netbird.clients;

          # netbird manages /etc/ssh/ssh_config.d/99-netbird.conf dynamically
          # for `netbird ssh` peer proxying. hardened mode keeps /etc read-only,
          # so allow only the upstream-owned ssh config drop-in directory.
          systemd.services.netbird.serviceConfig.ReadWritePaths = [ "/etc/ssh/ssh_config.d" ];

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
        (lib.optionalAttrs hasPreservation {
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
        })
      ];
    };
}
