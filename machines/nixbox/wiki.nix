{ inputs, ... }:
let
  port = 8086;
in
{
  nixfiles.caddy.vhosts.fosskar = {
    inherit port;
  };

  services.static-web-server = {
    enable = true;
    listen = "0.0.0.0:${toString port}";
    root = inputs.wiki.packages.x86_64-linux.default;
  };
}
