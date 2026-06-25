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
            # quality profiles are guide-backed: importing by trash_id auto-syncs
            # every custom format the profile scores (tiers, HDR, unwanted, streaming,
            # audio, repack), so no separate custom_formats / custom_format_groups needed
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
                {
                  trash_id = "c4cadd6b35b95f62c3d47a408e53e2f7"; # WEB-2160p (Combined)
                  reset_unmatched_scores.enabled = true;
                }
              ];
              # not carried by the profile: block DV-only (green/purple on non-DV
              # clients). SDR left allowed (WEB-only profile, lets 4k WEB upgrade)
              custom_formats = [
                {
                  trash_ids = [
                    "9b27ab6498ec0f31a3353992e19434ca" # DV (w/o HDR fallback)
                  ];
                  assign_scores_to = [ { name = "WEB-2160p (Combined)"; } ];
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
                {
                  trash_id = "d1d310673359205736b4b84acd5ea8c8"; # Remux 2160p (Combined)
                  reset_unmatched_scores.enabled = true;
                }
              ];
              # not carried by the profile: block DV-only (green/purple on non-DV
              # clients) and SDR remux/bluray, but allow SDR WEB so 4k WEB still upgrades
              custom_formats = [
                {
                  trash_ids = [
                    "923b6abef9b17f937fab56cfcf89e1f1" # DV (w/o HDR fallback)
                    "25c12f78430a3a23413652cbd1d48d77" # SDR (no WEBDL)
                  ];
                  assign_scores_to = [ { name = "Remux 2160p (Combined)"; } ];
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
