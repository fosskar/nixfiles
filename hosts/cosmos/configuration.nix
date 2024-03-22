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
    ./hardware-configuration.nix
    ./hardware.nix
    ./xdg.nix
    ./network.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./xserver.nix
    ../../system/audio.nix
    ../../system/fonts.nix
    ../../system/locale.nix
    ../../system/filemanager/thunar.nix
    ../../system/gaming/gamemode.nix
    ../../system/gaming/steam.nix
    ../../system/gaming/gamescope.nix
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
      # The Magic SysRq key is a key combo that allows users connected to the
      # system console of a Linux kernel to perform some low-level commands.
      # Disable it, since we don't need it, and is a potential security concern.
      "kernel.sysrq" = 0;
      # Avoid swapping (locking pages that introduces latency and uses disk IO) unless the system has no more free memory
      "vm.swappiness" = 20; # because of ZRAM swap more aggresivly
      # zram is in memory, no need to readahead
      # page-cluster refers to the number of pages up to which
      # consecutive pages are read in from swap in a single attempt
      "vm.page-cluster" = 0;
      "vm.max_map_count" = 16777216; # increasing is good for gaming
      # If you have enough free RAM increase the watermark scale factor to further reduce the likelihood of allocation stalls (explanations [7][8]). Setting watermark distances to 5% of RAM:
      "vm.watermark_scale_factor" = 500;
      # Proactive compaction for (Transparent) Hugepage allocation reduces the average but not necessarily the maximum allocation stalls. Disable proactive compaction because it introduces jitter according to kernel documentation (inner workings):
      "vm.compaction_proactiveness" = 0;
      # If you have enough free RAM increase the number of minimum free Kilobytes to avoid stalls on memory allocations: [5][6]. Do not set this below 1024 KB or above 5% of your systems memory. Reserving 1GB:
      "vm.min_free_kbytes" = 1048576;
      # Disable zone reclaim (locking and moving memory pages that introduces latency spikes)
      "vm.zone_reclaim_mode" = 0;
      # Reduce the watermark boost factor to defragment only one pageblock (2MB on 64-bit x86) in case of memory fragmentation. After a memory fragmentation event this helps to better keep the application data in the last level processor cache.
      "vm.watermark_boost_factor" = 1;
      # Reduce the maximum page lock acquisition latency while retaining adequate throughput [13][14][15]:
      "vm.page_lock_unfairness" = 1;
      # enable BBR congestion control # Bufferbloat mitigations + slight improvement in throughput & latency
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";
      ## TCP optimization
      # TCP Fast Open is a TCP extension that reduces network latency by packing
      # data in the sender’s initial TCP SYN. Setting 3 = enable TCP Fast Open for
      # both incoming and outgoing connections:
      "net.ipv4.tcp_fastopen" = 3;
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
