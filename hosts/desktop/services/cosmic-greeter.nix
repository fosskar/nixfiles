{
  pkgs,
  ...
}:
{
  # cosmic-greeter display manager
  # wayland-native greeter for cosmic desktop environment
  # integrates with hyprland via uwsm session management
  services.displayManager.cosmic-greeter = {
    enable = true;
    # package = pkgs.cosmic-greeter; # use default package
  };
}