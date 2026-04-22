{
  flake.modules.nixos.harmonia =
    { config, lib, ... }:
    {
      options.nixfiles.harmonia = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 5000;
          description = "harmonia listen port";
        };

        signKeyPaths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "private cache signing keys for harmonia";
        };
      };

      config =
        let
          cfg = config.nixfiles.harmonia;
        in
        {
          services.harmonia.cache = {
            enable = true;
            settings.bind = "[::]:${toString cfg.port}";
            inherit (cfg) signKeyPaths;
          };

          nix.settings.allowed-users = lib.mkAfter [ "harmonia" ];
          networking.firewall.allowedTCPPorts = [ cfg.port ];
        };
    };
}
