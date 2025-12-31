{ pkgs, ... }:
{
  boot = {
    # FIXME wait to cache for cachyos kernel
    # pkgs.cachyosKernels.linuxPackages-cachyos-latest
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      # kernel lockdown disabled for sched-ext scheduler with BPF functionality
      "lockdown=none"

      # disable watchdog timer
      "nowatchdog"

      # verbose boot - show systemd status
      "boot.shell_on_fail"
      "loglevel=4"

      # disable legacy serial port probing - no real serial ports on modern workstations
      "8250.nr_uarts=0"
    ];

    # watchdog modules not needed on workstation
    blacklistedKernelModules = [
      "sp5100_tco" # amd ryzen watchdog
      "iTCO_wdt" # intel watchdog
    ];
  };
}
