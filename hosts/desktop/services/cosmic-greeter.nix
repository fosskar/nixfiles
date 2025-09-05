_: {
  # cosmic-greeter display manager
  # wayland-native greeter for cosmic desktop environment
  services.displayManager.cosmic-greeter = {
    enable = true;
    # package = pkgs.cosmic-greeter; # use default package
  };
}
