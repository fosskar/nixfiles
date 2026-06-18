{
  flake.modules.nixos.nostrRelay =
    { lib, options, ... }:
    let
      listenAddress = "0.0.0.0";
      listenPort = 7777;
    in
    {
      config = {
        services.strfry = {
          enable = true;
          settings.relay = {
            bind = listenAddress;
            port = listenPort;
            info = {
              name = "personal relay";
              description = "personal nostr relay";
            };
            logging.invalidEvents = false;
          };
        };
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/strfry";
            user = "strfry";
            group = "strfry";
          }
        ];
      };
    };
}
