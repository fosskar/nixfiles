{ ... }:
{
  sops.secrets = {
    "admin-password" = {
      owner = "grafana";
      group = "grafana";
    };

    "grafana-oauth-client-id" = {
      owner = "grafana";
      group = "grafana";
    };

    "grafana-oauth-client-secret" = {
      owner = "grafana";
      group = "grafana";
    };

    "pve-exporter-envs" = {
      owner = "pve-exporter";
      group = "pve-exporter";
    };
  };
}
