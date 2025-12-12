_: {
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

      # because we use more cranular earlyoom - we wait for better oomd implementation
      oomd.enable = false;
    };
}
