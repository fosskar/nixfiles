_: {
  sops.secrets = {
    "newt.env" = { };

    "arr-stack.env" = { };

    "samba-user-passwords" = { };

    "admin-password" = {
      mode = "0444";
    };

    "paperless.env" = { };

    "beszel.env" = { };
  };
}
