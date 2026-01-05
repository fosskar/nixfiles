_: {
  sops.secrets = {
    "nix-access-tokens" = {
      mode = "0440";
      group = "users";
    };
  };
}
