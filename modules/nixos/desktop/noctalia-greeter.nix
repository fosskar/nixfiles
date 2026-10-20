{
  flake.modules.nixos.noctalia-greeter =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    {
      config = {
        # the nixpkgs module leaves XDG_DATA_DIRS unset, so the greeter finds no sessions
        services.greetd.settings.default_session.command = lib.concatStringsSep " " [
          (lib.getExe' pkgs.coreutils "env")
          "XDG_DATA_DIRS=${config.services.displayManager.sessionData.desktops}/share"
          (lib.getExe' config.services.displayManager.noctalia-greeter.package "noctalia-greeter-session")
        ];
        services.displayManager.noctalia-greeter = {
          enable = true;
          settings.appearance.hide_logo = true;
          # shell.greeter_sync.auto_sync syncs unattended only with a polkit rule
          # for org.noctalia.greeter.sync-appearance.
          passwordlessSyncUsers = [ "simon" ];
        };
      }
      // lib.optionalAttrs (options ? preservation) {
        # greeter state (synced appearance, remembered scheme) lives here.
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/noctalia-greeter";
            user = "greeter";
            group = "greeter";
          }
        ];
      };
    };
}
