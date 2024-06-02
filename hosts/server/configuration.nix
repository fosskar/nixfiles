############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{
  pkgs,
  inputs,
  ...
}: {
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

  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      timeout = 2;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  environment.noXlibs = false;

  documentation.info.enable = false;

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L"
    ];
    dates = "2:00";
    randomizedDelaySec = "30min";
  };

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

  ## flakes nix
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      allowed-users = ["root" "oscar" "@wheel"];
      trusted-users = ["root" "oscar" "@wheel"];
    };
  };

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
