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
    ./services.nix
    ../../system/locale.nix
    ../../system/virtualisation.nix
    ../../system/k3s.nix
    ./ssh.nix
    ./security.nix
    ./users.nix
    ../../system/vaultwarden.nix
    ../../system/monitoring/default.nix
    ../../system/monitoring/dashy.nix
    ../../system/monitoring/cockpit.nix
    ../../system/network/pihole.nix
    ../../system/network/unbound.nix
  ];

  ## systemd-boot
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

  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 20;
    swapDevices = 1;
  };

  ## programs
  programs = {
    zsh = {
      enable = true;
    };
    dconf = {
      enable = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
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
