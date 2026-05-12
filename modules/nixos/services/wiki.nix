{
  flake.modules.nixos.wiki =
    { inputs, pkgs, ... }:
    let
      port = 8086;
    in
    {
      services.caddy.virtualHosts."fosskar.nx3.eu".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';

      services.static-web-server = {
        enable = true;
        listen = "127.0.0.1:${toString port}";
        root = inputs.wiki.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      services.anubis.instances.bliki.settings = {
        TARGET = "http://127.0.0.1:${toString port}";
        BIND = "0.0.0.0:8098";
        BIND_NETWORK = "tcp";
        METRICS_BIND = "127.0.0.1:8099";
        METRICS_BIND_NETWORK = "tcp";
      };
    };
}
