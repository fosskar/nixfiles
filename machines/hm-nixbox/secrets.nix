{ ... }:
{
  sops.secrets = {
    "newt.env" = { };

    "pangolin.env" = { };

    "samba-user-passwords" = { };

    "admin-password" = {
      mode = "0444";
    };

    "homepage.env" = { };

    "immich.env" = { };

    "paperless.env" = { };
  };
}
