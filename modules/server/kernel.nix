{ lib, ... }:
{
  security = {
    protectKernelImage = true;
    lockKernelModules = false;
    forcePageTableIsolation = true;
    allowUserNamespaces = true;
    allowSimultaneousMultithreading = true;
  };

  boot = {
    kernelModules = [ "nf_conntrack" ];

    kernel.sysctl = {
      # inotify limits
      "fs.inotify.max_user_watches" = 1048576;
      "fs.inotify.max_user_instances" = 1024;
      "fs.inotify.max_queued_events" = 32768;

      # security
      "kernel.sysrq" = lib.mkForce 0;
      "kernel.kptr_restrict" = 2;
      "kernel.ftrace_enabled" = false;
      "kernel.dmesg_restrict" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;
      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;
      "kernel.printk" = "3 3 3 3";
      "dev.tty.ldisc_autoload" = 0;
      "kernel.kexec_load_disabled" = true;
      "vm.mmap_min_addr" = 65536;
    };

    kernelParams = [
      "nohibernate"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "slab_nomerge"
      "debugfs=off"
      "oops=panic"
      "page_poison=on"
      "page_alloc.shuffle=1"
      "slub_debug=FZP"
      "rootflags=noatime"
      "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"
      "integrity_audit=1"
      "vm.swappiness=0"
      # note: module.sig_enforce and lockdown skipped (breaks VMs)
    ];

    blacklistedKernelModules = [
      # obscure network protocols
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "n-hdlc"
      "netrom"
      "x25"
      "ax25"
      "rose"
      "decnet"
      "econet"
      "af_802154"
      "ipx"
      "appletalk"
      "psnap"
      "p8022"
      "p8023"
      "can"
      "atm"

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
