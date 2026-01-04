_: {
  sops.secrets = {

    "u2f_keys" = { };

    "nix-access-tokens" = {
      mode = "0440";
      group = "users";
    };

    "samba-password" = { };
  };
}
