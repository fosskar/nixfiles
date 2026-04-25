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
        listen = "0.0.0.0:${toString port}";
        root = inputs.wiki.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
}
