{ lib, ... }:
let
  timeoutConfig = ''
    DefaultTimeoutStartSec=10s
    DefaultTimeoutStopSec=10s
    DefaultTimeoutAbortSec=10s
    DefaultDeviceTimeoutSec=10s
  '';
in
{
  systemd = {
    # shorter timeouts to avoid hanging on boot/shutdown
    user.extraConfig = lib.mkDefault timeoutConfig;

    # use systemd-oomd for out-of-memory handling
    oomd.enable = lib.mkDefault true;
  };
}
