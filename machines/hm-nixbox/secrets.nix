_: {
  sops.secrets = {
    "newt.env" = { };

    "arr-stack.env" = { };

    "samba-user-passwords" = { };

    "admin-password" = {
      mode = "0444";
    };

    "immich.env" = { };

    "paperless.env" = { };

    "beszel.env" = { };
  };
}
