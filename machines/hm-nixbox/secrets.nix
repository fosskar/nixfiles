{ ... }:
{
  sops.secrets = {
    "newt.env" = { };

    "pangolin.env" = { };

    "admin-password" = {
      owner = "grafana";
      group = "grafana";
    };

    "homepage.env" = { };

    "immich.env" = { };
  };
}
