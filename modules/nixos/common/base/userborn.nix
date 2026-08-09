{
  flake.modules.nixos.base =
    { config, ... }:
    {
      services.userborn = {
        enable = true;
        # outside /etc to survive an etc.overlay; persisted on ephemeral hosts.
        passwordFilesLocation = "/var/lib/nixos";
      };

      # uids and gids are auto-allocated and recorded here. without this map a
      # restored host hands out different numbers than the ownership on disk.
      clan.core.state.userborn.folders = [ config.services.userborn.passwordFilesLocation ];
    };
}
