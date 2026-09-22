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
        # resolved opens one udp socket per upstream transaction; a lookup burst
        # past the 1024 default hits EMFILE in accept4 and sd-event disables the
        # varlink listener for good, after which every nss lookup on the host
        # stalls until resolved restarts (sd-varlink.c connect_callback does not
        # treat EMFILE as retryable)
        services.systemd-resolved.serviceConfig.LimitNOFILE = 65536;
      };

      services.resolved = {
        enable = lib.mkDefault true;
        # srvos.server sets llmnr, but desktop doesn't - keep for both
        settings.Resolve.LLMNR = lib.mkDefault "false";
      };
    };
}
