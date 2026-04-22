{
  flake.modules.nixos.tailscale = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    nixfiles.preservation.directories = [
      "/var/cache/tailscale"
      "/var/lib/tailscale"
    ];
  };
}
