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
            sonarr.series = {
              base_url = "http://127.0.0.1:8989";
              api_key = "!env_var SONARR_API_KEY";
              quality_definition.type = "series";
              delete_old_custom_formats = true;
              include = [
                { template = "sonarr-quality-definition-series"; }
                { template = "sonarr-v4-quality-profile-web-1080p"; }
                { template = "sonarr-v4-custom-formats-web-1080p"; }
              ];
            };
            radarr.movies = {
              base_url = "http://127.0.0.1:7878";
              api_key = "!env_var RADARR_API_KEY";
              quality_definition.type = "movie";
              delete_old_custom_formats = true;
              include = [
                { template = "radarr-quality-definition-movie"; }
                { template = "radarr-quality-profile-remux-web-1080p"; }
                { template = "radarr-custom-formats-remux-web-1080p"; }
              ];
            };
          };
        };

        # --- systemd ---

        # inject api keys from sonarr/radarr configs into recyclarr.yml at runtime
        # runs as root (+) after nixpkgs preStart creates the yml with !env_var placeholders
        systemd.services.recyclarr.serviceConfig.ExecStartPre = lib.mkAfter [
          "+${pkgs.writeShellScript "recyclarr-inject-keys" ''
            SONARR_API_KEY=$(${pkgs.gnugrep}/bin/grep -oP '<ApiKey>\K[^<]+' /var/lib/sonarr/.config/NzbDrone/config.xml)
            RADARR_API_KEY=$(${pkgs.gnugrep}/bin/grep -oP '<ApiKey>\K[^<]+' /var/lib/radarr/.config/Radarr/config.xml)
            ${pkgs.gnused}/bin/sed -i "s|!env_var SONARR_API_KEY|$SONARR_API_KEY|; s|!env_var RADARR_API_KEY|$RADARR_API_KEY|" /var/lib/recyclarr/config.json
            chown recyclarr:recyclarr /var/lib/recyclarr/config.json
          ''}"
        ];
      };
    };
}
