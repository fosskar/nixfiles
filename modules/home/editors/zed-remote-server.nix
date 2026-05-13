{
  flake.modules.homeManager.zedRemoteServer = {
    programs.zed-editor = {
      enable = true;
      installRemoteServer = true;
    };
  };
}
