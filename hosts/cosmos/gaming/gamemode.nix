{pkgs, ...}: {
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        softrealtime = "auto";
        renice = 15;
      };
      #gpu = {
      #  apply_gpu_optimisations = "accept-responsibility";
      #  gpu_device = 0;
      #  amd_performance_level = "high";
      #};
    };
  };
  security.wrappers = {
    gamemode = {
      owner = "root";
      group = "root";
      source = "${pkgs.gamemode}/bin/gamemoderun";
      capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
    };
  };
}
