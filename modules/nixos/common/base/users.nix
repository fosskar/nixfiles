{
  flake.modules.nixos.base = _: {
    users = {
      mutableUsers = false; # disable useradd + passwd
    };
    #services.userborn.enable = true;
  };
}
