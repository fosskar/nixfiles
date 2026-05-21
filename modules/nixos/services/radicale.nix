{
  flake.modules.nixos.radicale = {
    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "127.0.0.1:5232" ];
        auth.type = "http_x_remote_user";
        storage.filesystem_folder = "/var/lib/radicale/collections";
      };
    };

    clan.core.state.radicale.folders = [ "/var/lib/radicale" ];

    preservation.preserveAt."/persist".directories = [
      {
        directory = "/var/lib/radicale";
        user = "radicale";
        group = "radicale";
      }
    ];
  };
}
