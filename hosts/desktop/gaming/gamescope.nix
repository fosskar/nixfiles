_: {
  programs.gamescope = {
    enable = true;
    capSysNice = false; # FIXME https://discourse.nixos.org/t/unable-to-activate-gamescope-capsysnice-option/37843
    args = [
      "--rt"
      "--expose-wayland"
    ];
  };

  # doesn't work at the moment, so caps not set, but doesn't hurt to keep this here
  #security.wrappers.gamescope = {
  #  owner = "root";
  #  group = "root";
  #  source = "${config.programs.gamescope.package}/bin/gamescope";
  #  capabilities = "cap_sys_nice+pie";
  #};
}
