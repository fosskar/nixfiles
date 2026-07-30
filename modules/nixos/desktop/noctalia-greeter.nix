{
  flake.modules.nixos.noctalia-greeter =
    {
      inputs,
      lib,
      options,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      config = {
        programs.noctalia-greeter = {
          enable = true;
          package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
          settings.appearance.hide_logo = true;
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
