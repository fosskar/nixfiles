_: {
  flake.modules.homeManager.phonetpm =
    { pkgs, ... }:
    {
      # phonetpm and age-plugin-phone; pair once with `phonetpm pair <endpoint id>`
      home.packages = [ pkgs.local.phonetpm ];

      # the daemon tells the two sockets apart by their file names
      systemd.user.sockets.phonetpm = {
        Unit.Description = "phonetpm ssh-agent and control sockets";
        Socket = {
          ListenStream = [
            "%t/phonetpm/agent.sock"
            "%t/phonetpm/control.sock"
          ];
          SocketMode = "0600";
          DirectoryMode = "0700";
        };
        Install.WantedBy = [ "sockets.target" ];
      };

      systemd.user.services.phonetpm = {
        Unit = {
          Description = "phonetpm daemon";
          Requires = [ "phonetpm.socket" ];
        };
        Service.ExecStart = "${pkgs.local.phonetpm}/bin/phonetpm daemon";
      };
    };
}
