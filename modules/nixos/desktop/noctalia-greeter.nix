{
  flake.modules.nixos.noctalia-greeter =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      config = {
        services.displayManager.noctalia-greeter = {
          enable = true;
          package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
          settings.appearance.hide_logo = true;
          # shell.greeter_sync.auto_sync syncs unattended only with a polkit rule
          # for org.noctalia.greeter.sync-appearance.
          passwordless-sync-users = [ "simon" ];
        };
      };
    };
}
