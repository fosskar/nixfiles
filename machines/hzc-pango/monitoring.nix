{
  config,
  lib,
  pkgs,
  ...
}:
let
  mimirPasswordFile = config.clan.core.vars.generators.mimir-auth.files."password".path;
  lokiPasswordFile = config.clan.core.vars.generators.loki-auth.files."password".path;
  vectorConfig = (pkgs.formats.toml { }).generate "vector.toml" config.services.vector.settings;
in
{
  services.vector = {
    enable = true;
    package = pkgs.vector;
    validateConfig = false; # uses env vars for secrets
    settings = {
      sources = {
        crowdsec_metrics = {
          type = "prometheus_scrape";
          endpoints = [ "http://127.0.0.1:6060/metrics" ];
          scrape_interval_secs = 15;
        };
        traefik_metrics = {
          type = "prometheus_scrape";
          endpoints = [ "http://127.0.0.1:8082/metrics" ];
          scrape_interval_secs = 15;
        };
        traefik_logs = {
          type = "file";
          include = [ "/var/log/traefik/access.log" ];
        };
      };

      transforms = {
        labeled_metrics = {
          type = "remap";
          inputs = [
            "crowdsec_metrics"
            "traefik_metrics"
          ];
          source = ''
            .tags.instance = "hzc-pango"
          '';
        };
        parsed_logs = {
          type = "remap";
          inputs = [ "traefik_logs" ];
          source = ''
            . = parse_json!(.message)
            .instance = "hzc-pango"
          '';
        };
      };

      sinks = {
        mimir = {
          type = "prometheus_remote_write";
          inputs = [ "labeled_metrics" ];
          endpoint = "http://hm-nixbox.clan/mimir/api/v1/push";
          auth = {
            strategy = "basic";
            user = "alloy";
            password = "\${MIMIR_PASSWORD}";
          };
        };
        loki = {
          type = "loki";
          inputs = [ "parsed_logs" ];
          endpoint = "http://hm-nixbox.clan/loki";
          labels = {
            instance = "hzc-pango";
            job = "traefik-access";
          };
          auth = {
            strategy = "basic";
            user = "alloy";
            password = "\${LOKI_PASSWORD}";
          };
          encoding.codec = "json";
        };
      };
    };
  };

  systemd.services.vector.serviceConfig.LoadCredential = [
    "mimir-password:${mimirPasswordFile}"
    "loki-password:${lokiPasswordFile}"
  ];

  # wrap ExecStart to inject secrets as env vars from credentials
  systemd.services.vector.serviceConfig.ExecStart = lib.mkForce (
    pkgs.writeShellScript "vector-start" ''
      export MIMIR_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/mimir-password")"
      export LOKI_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/loki-password")"
      exec ${pkgs.vector}/bin/vector --config ${vectorConfig} --graceful-shutdown-limit-secs 60
    ''
  );
}
