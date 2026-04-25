{
  flake.modules.nixos.nostrRelay =
    let
      listenAddress = "0.0.0.0";
      listenPort = 7777;
    in
    {
      services.strfry = {
        enable = true;
        settings.relay = {
          bind = listenAddress;
          port = listenPort;
          info = {
            name = "crowbox relay";
            description = "personal nostr relay";
          };
          logging.invalidEvents = false;
        };
      };

      preservation.preserveAt."/persist".directories = [
        {
          directory = "/var/lib/strfry";
          user = "strfry";
          group = "strfry";
        }
      ];
    };
}
