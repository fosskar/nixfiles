{
  flake.modules.nixos.arrStack =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "jellyfin";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8096;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      pluginsDir = "${config.services.jellyfin.dataDir}/plugins";
      plugins = [
        pkgs.local.jellyfin-plugin-enhanced
        pkgs.local.jellyfin-plugin-intro-skipper
        pkgs.local.jellyfin-plugin-ldapauth
        pkgs.local.jellyfin-plugin-tvdb
      ];
      jq = lib.getExe pkgs.jq;
      xmlstarlet = lib.getExe pkgs.xmlstarlet;
      enhancedConfig = "${pluginsDir}/configurations/Jellyfin.Plugin.JellyfinEnhanced.xml";
      # only these fields are forced; anything else set in the plugin ui survives
      enhancedSettings = {
        JellyseerrEnabled = "true";
        JellyseerrUrls = "http://127.0.0.1:${toString config.services.seerr.port}";
        JellyseerrApiKey = "@SEERR_API_KEY@";
        JellyseerrAutoImportUsers = "true";
        # quality profile, server and folder can be picked per request
        JellyseerrShowAdvanced = "true";
        SyncJellyseerrWatchlist = "true";
        SyncJellyfinWatchlistToSeerr = "true";
        RecommendationsPageEnabled = "true";
        RecommendationsUseNativeTab = "true";
        DownloadsPageEnabled = "true";
        DownloadsUseNativeTab = "true";
        ActivityFeedEnabled = "true";
        ActivityFeedUseNativeTab = "true";
        StatusTagsEnabled = "true";
        QualityTagsEnabled = "true";
        # imdb and rotten tomatoes on title pages
        MdblistRatingsEnabled = "true";
        MdblistApiKey = "@MDBLIST_API_KEY@";
        MdblistRatingsSources = "imdb,tomatoes";
      };
    in
    {
      config = {
        # --- service ---

        services.jellyfin = {
          enable = true;
          openFirewall = false;
          group = "media";
          forceEncodingConfig = true;
          hardwareAcceleration = {
            enable = true;
            device = "/dev/nvidia0";
            type = "nvenc";
          };
          transcoding = {
            deleteSegments = true;
            enableHardwareEncoding = true;
            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
              vc1 = true;
              vp9 = true;
              av1 = true;
              hevc10bit = true;
            };
          };
        };

        users.users.jellyfin.extraGroups = [
          "render"
          "video"
        ];

        environment.systemPackages = [
          pkgs.jellyfin
          pkgs.jellyfin-web
          pkgs.jellyfin-ffmpeg
        ];

        systemd.tmpfiles.rules = [
          "d /dev/shm/jellyfin-transcodes 0750 jellyfin media -"
        ];

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "media" = [
              {
                "Jellyfin" = {
                  href = "https://${localHost}";
                  icon = "jellyfin.png";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Jellyfin";
            url = "https://${localHost}";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - jellyfin has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl} {
            flush_interval -1
          }
        '';

        # --- backup ---

        clan.core.state.jellyfin = {
          folders = [ "/var/backup/jellyfin" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/jellyfin
            sqlite3 -nofollow /var/lib/jellyfin/data/jellyfin.db ".backup '/var/backup/jellyfin/jellyfin.db'"
          '';
        };

        # --- systemd ---

        systemd.services.jellyfin.environment = {
          FONTCONFIG_FILE = pkgs.makeFontsConf {
            fontDirectories = [ pkgs.dejavu_fonts.minimal ];
            impureFontDirectories = [ ];
            includes = [ ];
          };
          XDG_CACHE_HOME = config.services.jellyfin.cacheDir;
        };

        systemd.services.jellyfin.serviceConfig.DeviceAllow = [
          "/dev/nvidiactl rw"
          "/dev/nvidia-modeset rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
        ];

        # intro skipper shells out to a bare `ffmpeg`
        systemd.services.jellyfin.path = [ pkgs.jellyfin-ffmpeg ];

        systemd.services.jellyfin.serviceConfig.LoadCredential = [
          "seerr-api-key:${config.clan.core.vars.generators.seerr-api.files.api-key.path}"
          "mdblist-api-key:${config.clan.core.vars.generators.mdblist.files.api-key.path}"
        ];

        clan.core.vars.generators.mdblist = {
          prompts.api-key = {
            description = "mdblist api key (https://mdblist.com/preferences/#api)";
            type = "hidden";
            persist = true;
          };
          files.api-key.restartUnits = [ "jellyfin.service" ];
        };

        # jellyfin rewrites meta.json at runtime, so it is a copy; other
        # installs of the same plugin guid, manual or older, are removed.
        # mkBefore: the nixos module's forceEncodingConfig script can `exit 0`
        systemd.services.jellyfin.preStart = lib.mkBefore (
          lib.concatMapStrings (plugin: ''
            guid=$(${jq} -r .guid ${plugin}/meta.json)
            dest=${pluginsDir}/${plugin.name}
            for meta in ${pluginsDir}/*/meta.json; do
              [ -e "$meta" ] || continue
              dir=$(dirname "$meta")
              if [ "$dir" != "$dest" ] && [ "$(${jq} -r .guid "$meta")" = "$guid" ]; then
                rm -rf -- "$dir"
              fi
            done
            mkdir -p "$dest"
            for f in ${plugin}/*; do
              [ "$(basename "$f")" = meta.json ] || ln -sfn "$f" "$dest/"
            done
            ${jq} '. + {status: "Active", autoUpdate: false}' ${plugin}/meta.json > "$dest/meta.json"
          '') plugins
          # the bind address exists only in network.xml; jellyfin writes the file
          # on first start
          + ''
            network=${config.services.jellyfin.configDir}/network.xml
            if [ -e "$network" ]; then
              ${xmlstarlet} ed -L \
                -d '/NetworkConfiguration/LocalNetworkAddresses/*' \
                -s '/NetworkConfiguration/LocalNetworkAddresses' -t elem -n string -v ${listenAddress} \
                "$network"
            fi
          ''
          # jellyfin loads a partial file and keeps its defaults for the rest.
          # the keys are substituted with shell builtins: argv is world-readable
          # in /proc/<pid>/cmdline
          + ''
            (
              enhanced=${enhancedConfig}
              umask 077
              mkdir -p "$(dirname "$enhanced")"
              [ -e "$enhanced" ] || echo '<PluginConfiguration/>' > "$enhanced"
              ${xmlstarlet} ed -L \
                ${
                  lib.concatStringsSep " \\\n  " (
                    lib.mapAttrsToList (
                      name: value:
                      "-d /PluginConfiguration/${name} -s /PluginConfiguration -t elem -n ${name} -v ${lib.escapeShellArg value}"
                    ) enhancedSettings
                  )
                } \
                "$enhanced"
              content=$(<"$enhanced")
              content=''${content//@SEERR_API_KEY@/$(<"$CREDENTIALS_DIRECTORY/seerr-api-key")}
              content=''${content//@MDBLIST_API_KEY@/$(<"$CREDENTIALS_DIRECTORY/mdblist-api-key")}
              printf '%s\n' "$content" > "$enhanced"
            )
          ''
        );
      };
    };
}
