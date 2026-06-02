{
  flake.modules.nixos.arrStack =
    {
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        # --- service ---

        services.recyclarr = {
          enable = true;
          schedule = "weekly";
          configuration = {
            # config-templates v8 dropped the runtime `include` templates;
            # inline the equivalent web-1080p / remux-web-1080p template bundles
            sonarr.series = {
              base_url = "http://127.0.0.1:8989";
              api_key = "!env_var SONARR_API_KEY";
              delete_old_custom_formats = true;
              quality_definition.type = "series";
              quality_profiles = [
                {
                  trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
                  reset_unmatched_scores.enabled = true;
                }
              ];
              custom_format_groups.add = [
                {
                  trash_id = "158188097a58d7687dee647e04af0da3"; # [Optional] Golden Rule HD
                  select = [
                    "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                  ];
                }
                {
                  # HD/UHD Streaming Boost CFs are required and always included;
                  # no `select` needed
                  trash_id = "85fae4a2294965b75710ef2989c850eb"; # [Streaming Services] HD/UHD boost
                }
                {
                  trash_id = "59c3af66780d08332fdc64e68297098f"; # [Unwanted] Unwanted Formats
                  select = [
                    "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1
                    "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                    "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
                    "6f808933a71bd9666531610cb8c059cc" # BR-DISK (BTN)
                    "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
                    "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
                    "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
                    "23297a736ca77c0fc8e70f8edd7ee56c" # Upscaled
                  ];
                }
              ];
            };
            radarr.movies = {
              base_url = "http://127.0.0.1:7878";
              api_key = "!env_var RADARR_API_KEY";
              delete_old_custom_formats = true;
              quality_definition.type = "movie";
              quality_profiles = [
                {
                  trash_id = "9ca12ea80aa55ef916e3751f4b874151"; # Remux + WEB 1080p
                  reset_unmatched_scores.enabled = true;
                }
              ];
              custom_format_groups.add = [
                {
                  trash_id = "f8bf8eab4617f12dfdbd16303d8da245"; # [Optional] Golden Rule HD
                  select = [
                    "dc98083864ea246d05a42df0d05f81cc" # x265 (HD)
                  ];
                }
                {
                  trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; # [Unwanted] Unwanted Formats
                  select = [
                    "b8cd450cbfa689c0259a01d9e29ba3d6" # 3D
                    "cae4ca30163749b891686f95532519bd" # AV1
                    "b6832f586342ef70d9c128d40c07b872" # Bad Dual Groups
                    "cc444569854e9de0b084ab2b8b1532b2" # Black and White Editions
                    "ed38b889b31be83fda192888e2286d83" # BR-DISK
                    "0a3f082873eb454bde444150b70253cc" # Extras
                    "e6886871085226c3da1830830146846c" # Generated Dynamic HDR
                    "90a6f9a284dff5103f6346090e6280c8" # LQ
                    "e204b80c87be9497a8a6eaff48f72905" # LQ (Release Title)
                    "712d74cd88bceb883ee32f773656b1f5" # Sing-Along Versions
                    "bfd8eb01832d646a0a89c4deb46f8564" # Upscaled
                  ];
                }
              ];
            };
          };
        };

        # --- systemd ---

        # inject api keys from sonarr/radarr configs into config.yml at runtime
        # runs as root (+) after nixpkgs preStart creates the yml with !env_var placeholders
        systemd.services.recyclarr.serviceConfig.ExecStartPre = lib.mkAfter [
          "+${pkgs.writeShellScript "recyclarr-inject-keys" ''
            SONARR_API_KEY=$(${pkgs.gnugrep}/bin/grep -oP '<ApiKey>\K[^<]+' /var/lib/sonarr/.config/NzbDrone/config.xml)
            RADARR_API_KEY=$(${pkgs.gnugrep}/bin/grep -oP '<ApiKey>\K[^<]+' /var/lib/radarr/.config/Radarr/config.xml)
            ${pkgs.gnused}/bin/sed -i "s|!env_var SONARR_API_KEY|$SONARR_API_KEY|; s|!env_var RADARR_API_KEY|$RADARR_API_KEY|" /var/lib/recyclarr/config.yml
            chown recyclarr:recyclarr /var/lib/recyclarr/config.yml
          ''}"
        ];
      };
    };
}
