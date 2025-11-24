{
  mylib,
  lib,
  ...
}:
{
  imports = [
    ../../../../modules/shared
    ../../../../modules/lxc
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  boot = {
    kernelModules = [ "tun" ];
  };

  nix.settings = {
    sandbox = false;
  };

  security.pam.services.sshd.allowNullPassword = true;
  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = lib.mkForce true;
        PermitEmptyPasswords = "yes";
      };
    };
    tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [ "--advertise-routes=10.0.0.0/24" ];
      interfaceName = "userspace-networking"; # The interface name for tunnel traffic. Use “userspace-networking” (beta) to not use TUN.
    };
  };
  networking = {
    hostId = "8425e349";
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
