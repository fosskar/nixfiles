{
  flake.modules.nixos.base = _: {
    users = {
      mutableUsers = false; # disable useradd + passwd
    };
    services.userborn = {
      enable = true;
      # store passwd/group/shadow outside /etc so they survive an etc.overlay.
      # /var/lib/nixos is persisted by preservation on ephemeral hosts and is
      # on the normal root elsewhere, so it survives either way. independent
      # of preservation.
      passwordFilesLocation = "/var/lib/nixos";
    };
  };
}
