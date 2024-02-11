{pkgs, ...}: {
  environment.systemPackages = with pkgs; [gamescope];

  programs.gamescope = {
    enable = true;
    capSysNice = false;
    args = ["--rt"];
  };

  #security.wrappers = {
  #  gamescope = {
  #    owner = "root";
  #    group = "root";
  #    source = "${pkgs.gamescope}/bin/gamescope";
  #    capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
  #  };
  #};
}
