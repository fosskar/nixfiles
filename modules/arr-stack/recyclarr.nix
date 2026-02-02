{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.arr-stack;
in
{
  config = lib.mkIf cfg.recyclarr.enable {
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

    systemd.services.recyclarr = {
      serviceConfig.EnvironmentFile = config.sops.secrets."arr-stack.env".path;
      preStart = ''
        ${pkgs.yq-go}/bin/yq -o yaml \
          'with((.. | select(kind == "scalar") | select(tag == "!!str") | select(test("^!env_var .*"))); . = sub("!env_var ", "") | . tag = "!env_var")' \
          /var/lib/recyclarr/config.json > /var/lib/recyclarr/recyclarr.yml
      '';
      serviceConfig.ExecStart = lib.mkForce "${pkgs.recyclarr}/bin/recyclarr sync --config /var/lib/recyclarr/recyclarr.yml";
    };
  };
}
