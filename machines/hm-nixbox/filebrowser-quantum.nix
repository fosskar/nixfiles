{
  imports = [ ../../modules/filebrowser-quantum ];

  users.users.filebrowser-quantum.extraGroups = [
    "shared"
    "media"
  ];

  services.filebrowser-quantum = {
    enable = true;
    port = 8081;
    settings = {
      auth.methods.proxy = {
        enabled = true;
        createUser = true;
        header = "Remote-User";
      };
      server.sources = [
        {
          name = "shares";
          path = "/tank/shares";
        }
        {
          name = "media";
          path = "/tank/media";
        }
      ];
      userDefaults.darkMode = true;
    };
  };
}
