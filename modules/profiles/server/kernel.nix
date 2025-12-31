_: {
  boot = {
    kernelModules = [ "nf_conntrack" ];

    kernelParams = [
      # auto-reboot on kernel panic (headless servers)
      "panic=1"
      "boot.panic_on_fail"

      # Disable slab merging which significantly increases the difficulty of heap
      # exploitation by preventing overwriting objects from merged caches and by
      # making it harder to influence slab cache layout (costs some performance)
      "slab_nomerge"

      # Disable debugfs which exposes sensitive information about the kernel
      "debugfs=off"

      # slub_debug=FZP removed - was exposing kernel addresses

      # ignore access time (atime) updates on files
      "rootflags=noatime"

      # linux security modules
      "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"

      # additional integrity auditing messages
      "integrity_audit=1"

      # vm.swappiness handled by base/zram.nix

      # note: module.sig_enforce and lockdown skipped (breaks VMs)
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
      "erofs"
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
}
