_: {
  boot = {
    kernelParams = [
      # Kernel lockdown disabled for sched-ext scheduler with BPF functionality
      "lockdown=none"

      # Disable watchdog timer
      "nowatchdog"

      # Disable USB autosuspend - prevents peripheral wake-up issues
      "usbcore.autosuspend=-1"

      # Quiet boot - cleaner boot screen
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    # Watchdog modules not needed on desktop
    blacklistedKernelModules = [
      "sp5100_tco" # AMD Ryzen watchdog
      "iTCO_wdt" # Intel watchdog
    ];
  };
}
