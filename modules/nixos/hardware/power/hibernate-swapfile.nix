_: {
  flake.modules.nixos.hibernateSwapfile =
    { lib, ... }:
    let
      path = "/swapfile";
      size = 64 * 1024;
      resumeDevice = "/dev/disk/by-label/nixos";
      resumeOffset = null;
      hibernateDelay = "30min";
    in
    {
      assertions = [
        {
          assertion = resumeOffset != null;
          message = ''
            hibernateSwapfile needs resumeOffset before import.
            Create the swapfile, then get it with:
              sudo filefrag -v ${path} | awk '$1 == "0:" {print $4}' | tr -d .
          '';
        }
      ];

      security.protectKernelImage = lib.mkForce false;

      swapDevices = [
        {
          device = path;
          inherit size;
        }
      ];

      boot.resumeDevice = resumeDevice;
      boot.kernelParams = [ "resume_offset=${toString resumeOffset}" ];

      services.logind.settings.Login = {
        HandleHibernateKey = lib.mkForce "hibernate";
        HandleLidSwitch = lib.mkForce "suspend-then-hibernate";
        HandleLidSwitchExternalPower = lib.mkForce "suspend-then-hibernate";
      };

      systemd.sleep.settings.Sleep.HibernateDelaySec = hibernateDelay;
    };
}
