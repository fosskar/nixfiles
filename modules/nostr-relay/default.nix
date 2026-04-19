_:
let
  port = 7777;
in
{
  services.strfry = {
    enable = true;
    settings.relay = {
      bind = "0.0.0.0";
      inherit port;
      info = {
        name = "crowbox relay";
        description = "personal nostr relay";
      };
      logging.invalidEvents = false;
    };
  };

  nixfiles.persistence.directories = [
    {
      directory = "/var/lib/strfry";
      user = "strfry";
      group = "strfry";
    }
  ];
}
