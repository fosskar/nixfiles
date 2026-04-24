{
  flake.modules.nixos.cosmic =
    { pkgs, ... }:
    {
      services = {
        displayManager.cosmic-greeter.enable = true;
        desktopManager.cosmic.enable = true;
      };

      # nm-applet not needed - cosmic has its own network indicator
      environment.cosmic.excludePackages = [ pkgs.networkmanagerapplet ];
    };
}
