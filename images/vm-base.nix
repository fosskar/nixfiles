{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  users = {
    users = {
      root = {
        hashedPassword = lib.mkForce "$y$j9T$yBays6ELhmm7.foDrjZhD0$GTwkBh4CkuFaBn20ydgHnEWd.igf2oIfZ4aOr99mJiD"; # set a invalid hashed or empty password "disables" root
        initialHashedPassword = lib.mkForce null;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE"
        ];
      };
    };
  };

  networking.hostId = "8425e349";

  services.qemuGuest.enable = true;

  hardware.firmware = lib.mkForce [ ];

  isoImage.includeSystemBuildDependencies = false;

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
