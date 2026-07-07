{
  flake.modules.nixos.opencloud =
    {
      lib,
      options,
      ...
    }:
    let
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

        services.gatus.settings.endpoints = [
          # tcp probe only: http check would create phantom X-Remote-User principal
          {
            name = "Radicale";
            url = "tcp://127.0.0.1:5232";
            group = "Files";
            conditions = [ "[CONNECTED] == true" ];
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
          }
        ];
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
