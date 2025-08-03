{ lib, ... }:
{
  systemd =
    let
      timeoutConfig = ''
        DefaultTimeoutStartSec=10s
        DefaultTimeoutStopSec=10s
        DefaultTimeoutAbortSec=10s
        DefaultDeviceTimeoutSec=10s
      '';
    in
    {
      #settings = {
      #  Manager = timeoutConfig;
      #};
      # Set the default timeout for starting, stopping, and aborting services to
      # avoid hanging the system for too long on boot or shutdown.
      user.extraConfig = timeoutConfig;

      # Disable (not) all virtual terminals. I usually don't need to switch between
      # TTYs, however, I may get locked out of my desktop session and this
      # may come to bite me in the ass when that happens.
      services = lib.mapAttrs (_: lib.mkForce) {
        "getty@tty1".enable = false;
        "autovt@tty1".enable = false;
        "getty@tty7".enable = false;
        "autovt@tty7".enable = false;
        "kmsconvt@tty1".enable = false;
        "kmsconvt@tty7".enable = false;
      };
      # because we use more cranular earlyoom - we wait for better oomd implementation
      oomd.enable = false;
    };
}
