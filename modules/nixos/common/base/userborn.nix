{
  flake.modules.nixos.base = _: {
    services.userborn = {
      enable = true;
      # outside /etc to survive an etc.overlay; persisted on ephemeral hosts.
      passwordFilesLocation = "/var/lib/nixos";
    };
  };
}
