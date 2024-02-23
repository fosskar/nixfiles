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
    kernelPackages = pkgs.linuxPackages_xanmod_latest; # pkgs.linuxPackages_xanmod_latest, pkgs.linuxPackages_zen, pkgs.linuxPackages_lqx, linuxPackages_latest
    kernel.sysctl = {
      "vm.swappiness" = 20; # because of ZRAM swap more aggresivly
      # zram is in memory, no need to readahead
      # page-cluster refers to the number of pages up to which
      # consecutive pages are read in from swap in a single attempt
      "vm.page-cluster" = 0;
      "vm.max_map_count" = 16777216; # increasing is good for gaming
    };
    kernelParams = [
      "amd_pstate=active"
    ];
  };

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
          "gamemode"
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
      # hyprland cachix
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
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
