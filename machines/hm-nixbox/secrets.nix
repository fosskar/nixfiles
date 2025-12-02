{ ... }:
{
  sops.secrets = {
    "newt.env" = { };

    "admin-password" = {
      owner = "grafana";
      group = "grafana";
    };

    "grafana-oidc-client-id" = {
      owner = "grafana";
      group = "grafana";
    };

    "grafana-oidc-client-secret" = {
      owner = "grafana";
      group = "grafana";
    };

    "pocket-id.env" = { };
  };
}
