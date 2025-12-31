_: {
  boot = {
    kernelParams = [
      # Disable password timeout
      "luks.options=timeout=0"
      "rd.luks.options=timeout=0"

      # Assume root device is already there, do not wait
      # for it to appear.
      "rootflags=x-systemd.device-timeout=0"
    ];
    # Mildly improves performance for the disk encryption
    initrd = {
      availableKernelModules = [
        "aesni_intel"
        "cryptd"
        "usb_storage"
      ];
      # LUKS
      luks.devices = {
        crypted = {
          device = "/dev/disk/by-uuid/06ca0895-ca77-48ab-9471-1fa5091f0a47";
          preLVM = true;
          bypassWorkqueues = true;
          allowDiscards = true;
        };
      };
    };
  };
  services.lvm.enable = true;
}
