{
  flake.modules.nixos.autoCpufreq = {
    services.power-profiles-daemon.enable = false;

    services.auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          energy_performance_preference = "power";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          energy_performance_preference = "balance_performance";
          turbo = "auto";
        };
      };
    };
  };
}
