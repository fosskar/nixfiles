_: {
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.t3code.desktop ];
    };

  # bound on all interfaces for mobile clients over the netbird mesh; the lan
  # stays closed because the port is not opened in the nixos firewall
  flake.modules.homeManager.t3codeServer =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.local.t3code ];

      systemd.user.services.t3code = {
        Unit.Description = "T3 Code server";
        Service = {
          ExecStart = "${pkgs.local.t3code}/bin/t3 serve --host 0.0.0.0 --port 3773";
          WorkingDirectory = "%h";
          # home-manager user units get no PATH; providers (pi, claude, codex)
          # and their tools come from the user and system profiles
          Environment = [ "PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin" ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
