{
  flake.modules.homeManager.bash = _: {
    programs.bash = {
      enable = true;
    };
  };
}
