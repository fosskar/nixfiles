{
  flake.modules.nixos.tailscale = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    preservation.preserveAt."/persist".directories = [
      "/var/cache/tailscale"
      "/var/lib/tailscale"
    ];
  };
}
