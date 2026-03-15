_: {
  sops.secrets = {
    "arr-stack.env" = { };

    "admin-password" = {
      mode = "0444";
    };

    "sabnzbd" = {
      owner = "sabnzbd";
    };
  };
}
