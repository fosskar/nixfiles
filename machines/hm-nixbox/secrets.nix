_: {
  sops.secrets = {
    "newt.env" = { };

    "arr-stack.env" = { };

    "samba-user-passwords" = { };

    "admin-password" = {
      mode = "0444";
    };

    "beszel.env" = { };

    "sabnzbd" = {
      owner = "sabnzbd";
    };
  };
}
