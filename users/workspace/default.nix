{
  home-manager.users.workspace = {
    home = {
      username = "workspace";
      homeDirectory = "/home/workspace";
      stateVersion = "25.11";
    };

    systemd.user.startServices = "sd-switch";
    nix.channels = { };
  };
}
