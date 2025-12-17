{ config, ... }:
{
  sops.secrets = {

    "u2f_keys" = { };

    "id_yubikey.pub" = {
      path = "${config.users.users.simon.home}/.ssh/id_yubikey.pub";
      owner = "simon";
      mode = "0600";
    };

    "nix-access-tokens" = {
      mode = "0440";
      group = "users";
    };
  };
}
