_: {
  # disabled: conflicts with steam's gamescope session - use steam's gamescopeSession instead
  programs.gamescope = {
    enable = false;
    capSysNice = true;
    args = [
      "--rt"
      "--expose-wayland"
    ];
  };
}
