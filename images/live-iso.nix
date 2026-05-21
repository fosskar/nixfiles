{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  hostName = "nixos";
in
{
  imports = [
    # base profiles see: https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/profiles
    "${modulesPath}/profiles/all-hardware.nix"

    # This module creates a bootable ISO image containing the given NixOS
    # configuration.  The derivation for the ISO image will be placed in
    # config.system.build.isoImage.
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  isoImage = {
    isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    makeEfiBootable = true;
    makeUsbBootable = true;
    appendToMenuLabel = " live";
    squashfsCompression = lib.mkDefault "zstd";
  };

  documentation = {
    enable = lib.mkForce false;
    man.enable = lib.mkForce false;
    doc.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  # so i can use my config directly

  services = {
    openssh.settings.PermitRootLogin = lib.mkForce "yes";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce [
      "btrfs"
      "reiserfs"
      "vfat"
      "f2fs"
      "xfs"
      "ntfs"
      "cifs"
    ];
    loader.grub.memtest86.enable = lib.mkForce false;
    # Make the installer more likely to succeed in low memory
    # environments.  The kernel's overcommit heustistics bite us
    # fairly often, preventing processes such as nix-worker or
    # download-using-manifests.pl from forking even if there is
    # plenty of free memory.
    kernel.sysctl."vm.overcommit_memory" = "1";
    swraid.enable = true;
    # remove warning about unset mail
    swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";
  };

  networking = {
    inherit hostName;
  };

  environment = {
    systemPackages = [
      pkgs.neovim
      pkgs.git

      pkgs.testdisk # useful for repairing boot problems
      pkgs.ms-sys # for writing Microsoft boot sectors / MBRs
      pkgs.efibootmgr
      pkgs.efivar
      pkgs.parted
      pkgs.gptfdisk
      pkgs.ddrescue
      pkgs.ccrypt
      pkgs.cryptsetup # needed for dm-crypt volumes

      # Some networking tools.
      pkgs.fuse
      pkgs.fuse3
      pkgs.sshfs-fuse
      pkgs.socat
      pkgs.screen
      pkgs.tcpdump

      # Hardware-related tools.
      pkgs.sdparm
      pkgs.hdparm
      pkgs.pciutils
      pkgs.usbutils
      pkgs.nvme-cli
    ];
    # Tell the Nix evaluator to garbage collect more aggressively.
    # This is desirable in memory-constrained environments that don't
    # (yet) have swap set up.
    variables.GC_INITIAL_HEAP_SIZE = "1M";
  };

  users = {
    mutableUsers = false;
    extraUsers.root.password = "nixos";
  };

  swapDevices = lib.mkImageMediaOverride [ ];
  fileSystems = lib.mkImageMediaOverride config.lib.isoFileSystems;

  system = {
    stateVersion = lib.version;
    # To speed up installation a little bit, include the complete
    # stdenv in the Nix store on the CD.
    extraDependencies = [
      pkgs.stdenv
      pkgs.stdenvNoCC # for runCommand
      pkgs.busybox
      pkgs.jq # for closureInfo
      # For boot.initrd.systemd
      pkgs.makeInitrdNGTool
    ];
  };
}
