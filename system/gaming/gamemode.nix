{pkgs, ...}: {
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
        inhibit_screensaver = 0;
      };
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
