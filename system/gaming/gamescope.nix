{config, ...}: {
  programs.gamescope = {
    enable = true;
    capSysNice = false;
    args = ["--rt"];
  };

  security.wrappers.gamescope = {
    owner = "root";
    group = "root";
    source = "${config.programs.gamescope.package}/bin/gamescope";
    capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
  };
}
