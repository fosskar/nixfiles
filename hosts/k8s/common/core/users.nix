{ config, ... }:
{
  users = {
    mutableUsers = true; # disable useradd + passwd

    users = {
      root = {
        hashedPasswordFile = config.sops.secrets."user/root/hashed_password".path; # set a invalid hashed or empty password "disables" root
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1zarKMo5sVMAn5f0ew4j82vHlkUOLp6BcdODKaUc85 simonoscr@proton.me"
        ];
      };
    };
  };
}
