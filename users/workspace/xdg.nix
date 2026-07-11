{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    # hm default flipped to false; keep exporting XDG_*_DIR like before
    setSessionVariables = true;
    # only the projects dir is wanted for this user
    desktop = null;
    music = null;
    publicShare = null;
    templates = null;
    videos = null;
  };
}
