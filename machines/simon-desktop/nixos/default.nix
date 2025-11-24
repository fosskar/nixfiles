{ inputs, mylib, ... }:
{
  imports = [
    inputs.chaotic.nixosModules.default
  ]
  ++ mylib.scanPaths ./. {
    exclude = [
    ];
  };

  # Essential system configuration
  nixpkgs.hostPlatform = "x86_64-linux";

  ### DON'T TOUCH!
  system.stateVersion = "24.11";
}
