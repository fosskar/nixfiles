_: {
  programs.gamescope = {
    enable = false; # this somehow prevents fucking gamescope to run when steam is enabled. i need to add the gamescopessions of steam to use nested gamescope
    capSysNice = true; # FIXME? https://discourse.nixos.org/t/unable-to-activate-gamescope-capsysnice-option/37843
    args = [
      "--rt"
      "--expose-wayland"
    ];
  };
}
