{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets = {
    pve-exporter-env = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/monitoring/envs.age";
    };
    grafana-admin-password = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/grafana/admin-password.age";
      owner = "grafana";
      group = "grafana";
    };
    grafana-oauth-client-id = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/grafana/oauth-client-id.age";
      owner = "grafana";
      group = "grafana";
    };
    grafana-oauth-client-secret = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/grafana/oauth-client-secret.age";
      owner = "grafana";
      group = "grafana";
    };
  };
}
