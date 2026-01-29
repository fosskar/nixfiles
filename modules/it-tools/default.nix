{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.it-tools;
in
{
  options.nixfiles.it-tools = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8087;
      description = "port for it-tools";
    };
  };

  config = {
    systemd.services.it-tools = {
      description = "it-tools static web server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd ${pkgs.it-tools}/lib --port ${toString cfg.port} --addr 127.0.0.1";
        DynamicUser = true;
        Restart = "on-failure";
      };
    };

    nixfiles.nginx.vhosts.tools.port = cfg.port;
  };
}
