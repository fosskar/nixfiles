{
  pkgs,
  lib,
  ...
}: {
  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      timeout = lib.mkDefault 1;
      generationsDir.copyKernels = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest; # pkgs.linuxPackages_xanmod_latest, pkgs.linuxPackages_zen, pkgs.linuxPackages_lqx, linuxPackages_latest
    kernelParams = [
      # auto means kernel will automatically decide the pti state
      "pti=auto" # on | off
      # CPU idle behaviour
      #  poll: slightly improve performance at cost of a hotter system (not recommended)
      #  halt: halt is forced to be used for CPU idle
      #  nomwait: Disable mwait for CPU C-states
      "idle=nomwait" # poll | halt | nomwait
      # disable displaying of the built-in Linux logo
      "logo.nologo"
      # disable usb autosuspend
      "usbcore.autosuspend=-1"
      "amd_pstate=active"
      "nohibernate"
      "nowatchdog"
      "modprobe.blacklist=sp5100_tco"
    ];
  };
}
