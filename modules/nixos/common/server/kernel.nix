{
  flake.modules.nixos.server =
    { lib, pkgs, ... }:
    {
      boot = {
        # the zfs module overrides this with the newest zfs-compatible kernel
        kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

        kernelModules = [ "nf_conntrack" ];

        kernelParams = [
          # auto-reboot on kernel panic (headless servers)
          "panic=1"
          "boot.panic_on_fail"

          # panic on kernel oops to stop exploits mid-flight; workstations keep
          # the default (kill the faulting task) and oops_limit=10000
          "oops=panic"

          # no slab merging: harder heap exploitation, costs some performance
          "slab_nomerge"

          # Disable debugfs which exposes sensitive information about the kernel
          "debugfs=off"

          # additional integrity auditing messages
          "integrity_audit=1"
        ];

        blacklistedKernelModules = [
          # audio (not needed on servers)
          "snd_hda_intel"
          "snd_hda_codec"
          "snd_hwdep"
          "snd_pcm"
          "snd_timer"
          "snd"
          "soundcore"

          # bluetooth (not needed on servers)
          "ath3k"
          "bluetooth"
          "btusb"

          # wifi (not needed on servers)
          "cfg80211"
          "rfkill"

          # rare filesystems
          "adfs"
          "affs"
          "bfs"
          "befs"
          "cramfs"
          "efs"
          "exofs"
          "freevxfs"
          "f2fs"
          "hfs"
          "hpfs"
          "jfs"
          "minix"
          "nilfs2"
          "ntfs"
          "omfs"
          "qnx4"
          "qnx6"
          "sysv"
          "ufs"
        ];
      };
    };
}
