{
  flake.modules.nixos.workstation =
    { lib, ... }:
    {
      systemd = {
        # shorter timeouts to avoid hanging on boot/shutdown
        user.settings.Manager = {
          DefaultTimeoutStartSec = lib.mkDefault "10s";
          DefaultTimeoutStopSec = lib.mkDefault "10s";
          DefaultTimeoutAbortSec = lib.mkDefault "10s";
          DefaultDeviceTimeoutSec = lib.mkDefault "10s";
        };

        # use systemd-oomd for out-of-memory handling
        oomd.enable = lib.mkDefault true;
      };
    };
}
