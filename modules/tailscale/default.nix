{ lib, config, ... }:
let
  cfg = config.nixfiles.tailscale;
in
{
  options.nixfiles.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "tailscale vpn";
    };
    trustInterface = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "add tailscale0 to firewall trusted interfaces";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.trustedInterfaces = lib.mkIf cfg.trustInterface [ "tailscale0" ];

    # persist tailscale state (if impermanence is used)
    environment.persistence."/persist".directories = [
      "/var/cache/tailscale"
      "/var/lib/tailscale"
    ];
  };
}
