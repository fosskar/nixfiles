############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{...}: {
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./ssh.nix
    ./users.nix
    ../../system/core/locale.nix
    ../../system/core/console.nix
    ../../system/core/zram.nix
    ../../system/hardware/fwupd.nix
    ../../system/nix/nixos.nix
    ../../system/nix/nh.nix
    ../../system/nix/nixpkgs.nix
    ../../system/nix/substituters.nix
    ../../system/programs/dconf.nix
    ../../system/programs/gnupg.nix
    ../../system/programs/zsh.nix
    ../../system/services/virtualisation.nix
    ../../system/services/kubernetes/k3s.nix
    ../../system/services/kubernetes/helm.nix
  ];

  environment.noXlibs = false;

  documentation.info.enable = false;

  systemd = {
    enableEmergencyMode = false;
    watchdog = {
      runtimeTime = "20s";
      rebootTime = "30s";
    };
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
