{
  flake.modules.nixos.base =
    { config, lib, ... }:
    {
      # mirrors srvos common/networking.nix so we don't depend on it staying there
      networking = {
        useNetworkd = lib.mkDefault true;
        dhcpcd.enable = lib.mkDefault false;
      };

      systemd = {
        # "online" is a broken concept, don't block boot on it
        network.wait-online.enable = false;

        services = lib.mkMerge (
          [
            {
              NetworkManager-wait-online.enable = false;

              # don't take the network down during nixos-rebuild switch
              systemd-networkd.stopIfChanged = false;
              systemd-resolved.stopIfChanged = false;
              # clan deploys over these meshes and a restart kills the deploy's own ssh
              # session, so new versions only take effect after a manual restart or reboot
              yggdrasil.restartIfChanged = false;
              p2p-ssh-iroh-iroh-ssh.restartIfChanged = false;

              # resolved opens one udp socket per upstream transaction; a lookup burst
              # past the 1024 default hits EMFILE in accept4 and sd-event disables the
              # varlink listener for good, after which every nss lookup on the host
              # stalls until resolved restarts (sd-varlink.c connect_callback does not
              # treat EMFILE as retryable)
              systemd-resolved.serviceConfig.LimitNOFILE = 65536;
            }
          ]
          ++ lib.mapAttrsToList (_: client: {
            ${client.service.name}.restartIfChanged = false;
          }) config.services.netbird.clients
          ++ lib.mapAttrsToList (
            name: interface:
            {
              "wireguard-${name}".restartIfChanged = false;
            }
            # peer unit names mirror peerUnitServiceName in nixpkgs wireguard.nix
            // lib.listToAttrs (
              map (
                peer:
                let
                  refresh =
                    (
                      if peer.dynamicEndpointRefreshSeconds != null then
                        peer.dynamicEndpointRefreshSeconds
                      else
                        interface.dynamicEndpointRefreshSeconds
                    ) != 0;
                in
                lib.nameValuePair "wireguard-${name}-peer-${peer.name}${lib.optionalString refresh "-refresh"}" {
                  restartIfChanged = false;
                }
              ) interface.peers
            )
          ) config.networking.wireguard.interfaces
        );
      };

      services.resolved = {
        enable = lib.mkDefault true;
        # srvos.server sets llmnr, but desktop doesn't - keep for both
        settings.Resolve.LLMNR = lib.mkDefault "false";
      };
    };
}
