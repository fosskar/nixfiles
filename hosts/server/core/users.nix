{ config, ... }:
{
  sops.secrets.dXNlcl9wYXNzd29yZA.neededForUsers = true;
  users = {
    mutableUsers = true; # disable useradd + passwd

    users = {
      root = {
        hashedPasswordFile = config.sops.secrets.dXNlcl9wYXNzd29yZA.path; # set a invalid hashed or empty password "disables" root
      };
    };
  };
}
