############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./audio.nix
    ../../modules/nixos/fonts.nix
    ./hardware-configuration.nix
    ./hardware.nix
    ./xdg.nix
    ../../modules/nixos/locale.nix
    ./network.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./xserver.nix
    ../../modules/nixos/filemanager/thunar.nix
    #./graphics.nix
    ./gaming/gamemode.nix
    ./gaming/steam.nix
    ./gaming/gamescope.nix
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
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    kernel.sysctl = {
      "vm.swappiness" = 20;
    };
    kernelParams = [
      "amdgpu.ppfeaturemask=0xfff7ffff"
      "amd_pstate=passive"
    ];
  };

  powerManagement.cpuFreqGovernor = "performance";
  documentation.nixos.enable = false;
  systemd.oomd.enable = false;

  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 5;
    memoryPercent = 20;
  };

  ## user
  users = {
    groups.simon.gid = 1000;
    users = {
      simon = {
        initialPassword = "123";
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "video"
        ];
      };
    };
    defaultUserShell = pkgs.zsh;
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
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
