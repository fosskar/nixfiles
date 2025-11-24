{ lib, ... }:
{
  security = {
    protectKernelImage = true;

    # vms don't have the same module loading concerns as bare-metal
    lockKernelModules = false;

    forcePageTableIsolation = true;

    allowUserNamespaces = true;

    allowSimultaneousMultithreading = true;
  };

  boot = {
    kernelModules = [ "nf_conntrack" ];

    kernel = {
      sysctl = {
        # forwarding (vms might route traffic)
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;

        # TCP hardening
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_rfc1337" = 1;
        "net.ipv4.conf.all.log_martians" = true;
        "net.ipv4.conf.default.log_martians" = true;
        "net.ipv4.icmp_echo_ignore_broadcasts" = true;
        "net.ipv6.conf.default.accept_ra" = 0;
        "net.ipv6.conf.all.accept_ra" = 0;
        "net.ipv4.tcp_timestamps" = 0;

        # TCP optimization (vm-appropriate values)
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "fq"; # fq works better with virtio than cake

        # network tuning (lighter for vms)
        "net.core.optmem_max" = 65536;
        "net.core.rmem_default" = 262144;
        "net.core.rmem_max" = 8388608;
        "net.core.somaxconn" = 16384;
        "net.core.wmem_default" = 262144;
        "net.core.wmem_max" = 8388608;
        "net.ipv4.ip_local_port_range" = "32768 65535";
        "net.ipv4.tcp_max_syn_backlog" = 4096;
        "net.ipv4.tcp_max_tw_buckets" = 1000000;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.ipv4.tcp_rmem" = "4096 262144 8388608";
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_tw_reuse" = 1;
        "net.ipv4.tcp_wmem" = "4096 65536 8388608";
        "net.ipv4.udp_rmem_min" = 8192;
        "net.ipv4.udp_wmem_min" = 8192;

        # connection tracking (lighter for vms)
        "net.netfilter.nf_conntrack_generic_timeout" = 60;
        "net.netfilter.nf_conntrack_max" = 524288;
        "net.netfilter.nf_conntrack_tcp_timeout_established" = 600;
        "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 1;

        # neighbor cache (lighter for vms)
        "net.ipv4.neigh.default.gc_thresh1" = 2048;
        "net.ipv4.neigh.default.gc_thresh2" = 4096;
        "net.ipv4.neigh.default.gc_thresh3" = 8192;
        "net.ipv4.neigh.default.gc_interval" = 60;
        "net.ipv4.neigh.default.gc_stale_time" = 120;

        # inotify settings
        "fs.inotify.max_user_watches" = 1048576;
        "fs.inotify.max_user_instances" = 1024;
        "fs.inotify.max_queued_events" = 32768;

        ### SECURITY (vm-appropriate subset)
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
    };
    kernelParams = [
      "nohibernate"
      "randomize_kstack_offset=on"
      # vms don't need vsyscall=none as strictly (can break older software in vms)
      # "vsyscall=none"
      # lighter hardening for vms to avoid virtio conflicts
      # skip module.sig_enforce, lockdown=confidentiality, page_poison for vms
      "oops=panic"
      "page_alloc.shuffle=1"
      "rootflags=noatime"
      # simpler lsm stack for vms
      "lsm=landlock,lockdown,yama,integrity,apparmor"
      "vm.swappiness=0"
    ];

    # vms need fewer blacklisted modules (virtio might conflict)
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
      "hfs"
      "hpfs"
      "jfs"
      "minix"
      "nilfs2"
      "omfs"
      "qnx4"
      "qnx6"
      "sysv"
      "ufs"
    ];
  };
}
