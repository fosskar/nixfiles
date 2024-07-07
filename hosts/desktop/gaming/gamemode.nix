{ pkgs, ... }:
{
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        reaper_freq = 5;
        desiredgov = "performance";
        defaultgov = "powersave";
        softrealtime = "auto";
        renice = 15;
        ioprio = 0;
        inhibit_screensaver = 1; # https://nixos.wiki/wiki/Gamemode#Known_Errors
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 1;
        amd_performance_level = "high";
      };
    };
  };
}
