{ ... }:
{
  sops.secrets = {
    "newt.env" = { };

    "pangolin.env" = { };

    "samba-user-passwords" = { };

    "admin-password" = {
      owner = "grafana";
      group = "grafana";
    };

    "homepage.env" = { };

    "immich.env" = { };
  };
}
