{ pkgs, ... }:
{
  services = {
    displayManager.cosmic-greeter = {
      enable = false; # yeah its ugly
    };
    desktopManager.cosmic = {
      enable = false; # disabled - build failure (cosmic-settings-daemon)
    };
  };

  # nm-applet not needed - cosmic has its own network indicator
  environment.cosmic.excludePackages = [ pkgs.networkmanagerapplet ];
}
