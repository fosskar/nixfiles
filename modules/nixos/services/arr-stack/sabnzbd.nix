{
  flake.modules.nixos.arrStack =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mediaRoot = "/tank/media";
      serviceName = "sabnzbd";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8085;
      listenUrl = "http://${listenAddress}:${toString listenPort}";

      # add a provider by adding a line here, then rerun clan vars generate
      servers = {
        primary.priority = 0;
        secondary.priority = 1;
        tertiary.priority = 1;
      };

      # field -> prompt wording. clan only shows a description when it differs
      # from the prompt name, otherwise it prints a generic "enter the value"
      serverFields = {
        host = "hostname, e.g. news.example.com";
        username = "login username";
        password = "login password";
      };

      secretNames = lib.concatMap (
        server: map (field: "${server}-${field}") (lib.attrNames serverFields)
      ) (lib.attrNames servers);
    in

    {
      config = {
        # --- service ---

        # persist stores each prompt as a file of the same name, so clan reuses
        # the value on later runs instead of asking again, and no script is needed
        clan.core.vars.generators.sabnzbd = {
          files = lib.genAttrs secretNames (_: {
            owner = "sabnzbd";
          });
          prompts = lib.listToAttrs (
            lib.concatMap (
              server:
              lib.mapAttrsToList (
                field: hint:
                lib.nameValuePair "${server}-${field}" {
                  persist = true;
                  type = if field == "password" then "hidden" else "line";
                  description = "${server} usenet provider ${hint}";
                }
              ) serverFields
            ) (lib.attrNames servers)
          );
        };

        services.sabnzbd = {
          enable = true;
          openFirewall = false;
          group = "media";
          allowConfigWrite = true;
          # @name@ is replaced at preStart, so only the pattern reaches the store
          secretValues = lib.listToAttrs (
            map (
              name: lib.nameValuePair "@${name}@" config.clan.core.vars.generators.sabnzbd.files.${name}.path
            ) secretNames
          );
          settings = {
            # the provider hostname is a secret, so the ini section key must not
            # be it. sabnzbd treats the key as an opaque id (clean_section_name
            # in sabnzbd/config.py) and reads the address from the host field.
            servers = lib.mapAttrs (
              server: settings:
              {
                name = "@${server}-host@";
                displayname = "@${server}-host@";
                host = "@${server}-host@";
                username = "@${server}-username@";
                password = "@${server}-password@";
                port = 563;
                ssl = true;
                ssl_verify = "strict";
                connections = 25;
                # the nullOr default renders as the literal string None
                expire_date = "";
              }
              // settings
            ) servers;
            misc = {
              port = listenPort;
              host_whitelist = "nixbox, ${localHost}";
              download_dir = "${mediaRoot}/downloads/incomplete";
              complete_dir = "${mediaRoot}/downloads/complete";
              permissions = "770";
            };
            categories = {
              movies.name = "movies";
              tv.name = "tv";
              music.name = "music";
              books.name = "books";
              podcasts = {
                name = "podcasts";
                script = "Default";
              };
              "*" = {
                name = "*";
                pp = 3;
                script = "Default";
              };
            };
          };
        };

        # keep group-write on created files so other media-group apps can manage them
        systemd.services.sabnzbd.serviceConfig.UMask = lib.mkForce "0002";

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "arr-stack" = [
              {
                "SABnzbd" = {
                  href = "https://${localHost}";
                  icon = "sabnzbd.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "SABnzbd";
            # backend check on purpose: the edge is forward-auth, authelia answers 302 without reaching the service
            url = listenUrl;
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.sabnzbd = {
          folders = [ "/var/backup/sabnzbd" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/sabnzbd
            sqlite3 /var/lib/sabnzbd/sabnzbd.db ".backup '/var/backup/sabnzbd/sabnzbd.db'"
          '';
        };
      };
    };
}
