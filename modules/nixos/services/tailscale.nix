{
  flake.modules.nixos.tailscale =
    { lib, options, ... }:
    {
      config = {
        services.tailscale = {
          enable = true;
          openFirewall = true;
        };
        networking.firewall.trustedInterfaces = [ "tailscale0" ];
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          "/var/cache/tailscale"
          "/var/lib/tailscale"
        ];
      };
    };
}
