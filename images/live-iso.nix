{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
with lib;
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
    squashfsCompression = mkDefault "zstd";
  };

  documentation = {
    enable = mkForce false;
    man.enable = mkForce false;
    doc.enable = mkForce false;
    nixos.enable = mkForce false;
  };

  nixpkgs = {
    hostPlatform = mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  # so i can use my config directly
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    extraOptions = "experimental-features = nix-command flakes";
    settings.trusted-users = [ "nixos" ];
  };

  services = {
    openssh.settings.PermitRootLogin = mkForce "yes";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = mkForce [
      "btrfs"
      "reiserfs"
      "vfat"
      "f2fs"
      "xfs"
      "ntfs"
      "cifs"
    ];
    loader.grub.memtest86.enable = mkForce false;
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
    systemPackages = with pkgs; [
      neovim
      git

      testdisk # useful for repairing boot problems
      ms-sys # for writing Microsoft boot sectors / MBRs
      efibootmgr
      efivar
      parted
      gptfdisk
      ddrescue
      ccrypt
      cryptsetup # needed for dm-crypt volumes

      # Some networking tools.
      fuse
      fuse3
      sshfs-fuse
      socat
      screen
      tcpdump

      # Hardware-related tools.
      sdparm
      hdparm
      pciutils
      usbutils
      nvme-cli
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

  swapDevices = mkImageMediaOverride [ ];
  fileSystems = mkImageMediaOverride config.lib.isoFileSystems;

  system = {
    stateVersion = version;
    # To speed up installation a little bit, include the complete
    # stdenv in the Nix store on the CD.
    extraDependencies = with pkgs; [
      stdenv
      stdenvNoCC # for runCommand
      busybox
      jq # for closureInfo
      # For boot.initrd.systemd
      makeInitrdNGTool
    ];
  };
}
