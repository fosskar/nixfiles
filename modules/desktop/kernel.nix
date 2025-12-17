{ pkgs, ... }:
{
  boot = {
    # FIXME wait to cache for cachyos kernel
    # pkgs.cachyosKernels.linuxPackages-cachyos-latest
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      # Kernel lockdown disabled for sched-ext scheduler with BPF functionality
      "lockdown=none"

      # Disable watchdog timer
      "nowatchdog"

      # Disable USB autosuspend - prevents peripheral wake-up issues
      "usbcore.autosuspend=-1"

      # verbose boot - show systemd status
      "boot.shell_on_fail"
      "loglevel=4"

      # disable legacy serial port probing - no real serial ports on modern desktops
      "8250.nr_uarts=0"
    ];

    # Watchdog modules not needed on desktop
    blacklistedKernelModules = [
      "sp5100_tco" # AMD Ryzen watchdog
      "iTCO_wdt" # Intel watchdog
    ];
  };
}
