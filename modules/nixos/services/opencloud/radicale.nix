{
  flake.modules.nixos.opencloud =
    {
      lib,
      options,
      ...
    }:
    let
      # radicale trusts X-Remote-User from any client, so only the opencloud
      # proxy may connect; a dead radicale shows up as a failed systemd unit
      radicaleClientMatch = ''meta skuid != "opencloud"'';
      radicaleRoute = endpoint: scriptName: {
        inherit endpoint;
        backend = "http://127.0.0.1:5232";
        remote_user_header = "X-Remote-User";
        skip_x_access_token = true;
        additional_headers = [ { "X-Script-Name" = scriptName; } ];
      };
    in
    {
      config = {
        services.opencloud.settings.proxy.additional_policies = [
          {
            name = "default";
            routes = [
              (radicaleRoute "/caldav/" "/caldav")
              (radicaleRoute "/.well-known/caldav" "/caldav")
              (radicaleRoute "/carddav/" "/carddav")
              (radicaleRoute "/.well-known/carddav" "/carddav")
            ];
          }
        ];

        # caldav/carddav backend; auth only works behind opencloud proxy (X-Remote-User)
        services.radicale = {
          enable = true;
          settings = {
            server = {
              hosts = [ "127.0.0.1:5232" ];
              ssl = false;
            };
            auth.type = "http_x_remote_user";
            web.type = "none";
            # native collection sharing (radicale 3.7+, beta), map-based.
            sharing = {
              type = "files";
              # must stay empty (explicit path crashes init in 3.7.4).
              database_path = "";
              collection_by_map = true;
              permit_create_map = true;
              default_permissions_create_map = "rw";
            };
            storage = {
              filesystem_folder = "/var/lib/radicale/collections";
              predefined_collections = builtins.toJSON {
                def-addressbook = {
                  "D:displayname" = "Address Book";
                  tag = "VADDRESSBOOK";
                };
                def-calendar = {
                  "C:supported-calendar-component-set" = "VEVENT,VJOURNAL,VTODO";
                  "D:displayname" = "Calendar";
                  tag = "VCALENDAR";
                };
              };
            };
          };
        };
        clan.core.state.radicale.folders = [ "/var/lib/radicale" ];

        networking.nftables.tables.radicale-clients = {
          family = "inet";
          content = ''
            chain output {
              type filter hook output priority filter; policy accept;
              ip daddr 127.0.0.1 tcp dport 5232 ${radicaleClientMatch} counter reject with tcp reset
            }
          '';
        };
        # the build sandbox lacks the runtime account; only the check uses root
        networking.nftables.preCheckRuleset = ''
          substituteInPlace ruleset.conf \
            --replace-fail '${radicaleClientMatch}' 'meta skuid != 0'
        '';
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/radicale";
            user = "radicale";
            group = "radicale";
          }
        ];
      };
    };
}
