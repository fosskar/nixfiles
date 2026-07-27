{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      # mirrors srvos common/networking.nix so we don't depend on it staying there
      networking = {
        useNetworkd = lib.mkDefault true;
        dhcpcd.enable = lib.mkDefault false;
      };

      systemd = {
        # "online" is a broken concept, don't block boot on it
        services.NetworkManager-wait-online.enable = false;
        network.wait-online.enable = false;

        # don't take the network down during nixos-rebuild switch
        services.systemd-networkd.stopIfChanged = false;
        services.systemd-resolved.stopIfChanged = false;
      };

      services.resolved = {
        enable = lib.mkDefault true;
        # srvos.server sets llmnr, but desktop doesn't - keep for both
        settings.Resolve.LLMNR = lib.mkDefault "false";
      };
    };
}
