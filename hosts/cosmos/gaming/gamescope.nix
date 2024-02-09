{pkgs, ...}: {
  #programs.gamescope = {
  #  enable = true;
  #};

  #security.wrappers = {
  #  gamescope = {
  #    owner = "simon";
  #    group = "wheel";
  #    source = "${pkgs.gamescope}/bin/gamescope";
  #    capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
  #  };
  #};
}
