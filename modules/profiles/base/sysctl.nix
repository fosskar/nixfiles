{ lib, ... }:
{
  boot.kernel.sysctl = {
    ### SECURITY (no mkDefault - should not be weakened)

    # The Magic SysRq key is a key combo that allows users connected to the
    # system console of a Linux kernel to perform some low-level commands.
    # Disable it, since we don't need it, and is a potential security concern.
    "kernel.sysrq" = lib.mkForce 0;

    # Hide kptrs even for processes with CAP_SYSLOG
    # also prevents printing kernel pointers
    "kernel.kptr_restrict" = 2;

    # Disable ftrace debugging
    "kernel.ftrace_enabled" = false;

    # Avoid kernel memory address exposures via dmesg
    # (this value can also be set by CONFIG_SECURITY_DMESG_RESTRICT)
    "kernel.dmesg_restrict" = 1;

    # Prevent creating files in potentially attacker-controlled environments such
    # as world-writable directories to make data spoofing attacks more difficult
    "fs.protected_fifos" = 2;

    # Prevent unintended writes to already-created files
    "fs.protected_regular" = 2;

    # Disable SUID binary dump
    "fs.suid_dumpable" = 0;

    # Prevent unprivileged users from creating hard or symbolic links to files
    "fs.protected_symlinks" = 1;
    "fs.protected_hardlinks" = 1;

    # Prevent boot console kernel log information leaks
    "kernel.printk" = "3 3 3 3";

    # Restrict loading TTY line disciplines to the CAP_SYS_MODULE capability to
    # prevent unprivileged attackers from loading vulnerable line disciplines with
    # the TIOCSETD ioctl
    "dev.tty.ldisc_autoload" = 0;

    # Kexec allows replacing the current running kernel. There may be an edge case where
    # you wish to boot into a different kernel, but I do not require kexec. Disabling it
    # patches a potential security hole in our system.
    "kernel.kexec_load_disabled" = true;

    # See:
    #  - <https://docs.kernel.org/admin-guide/sysctl/vm.html#mmap-rnd-bits>
    #  - <https://docs.kernel.org/admin-guide/sysctl/vm.html#mmap-min-addr>
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_min_addr" = 65536;

    ### PERFORMANCE (mkDefault - can be overridden)

    # Increase max file descriptors
    "fs.file-max" = lib.mkDefault 2097152;

    # Faster TCP port reuse - helps with high connection turnover
    "net.ipv4.tcp_fin_timeout" = lib.mkDefault 5;

    # Increase memory map limit - needed for wine/proton, Elasticsearch, etc.
    # overrides NixOS default of 1048576
    "vm.max_map_count" = 2147483642;

    ### NETWORK SECURITY (no mkDefault - should not be weakened)

    # prevent log flooding from malformed ICMP messages
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Reverse path filtering causes the kernel to do source validation of
    # packets received from all interfaces this can mitigate IP spoofing
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    # do not accept IP source route packets i am no router
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    # do not send ICMP redirects i am still no router
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    # refuse ICMP redirects mitm mitigation
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # helps in identifying suspicious network activity
    "net.ipv4.conf.all.log_martians" = true;
    "net.ipv4.conf.default.log_martians" = true;
    # prevents responding to broadcast pings
    "net.ipv4.icmp_echo_ignore_broadcasts" = true;
    # basic syn flood protection
    "net.ipv4.tcp_syncookies" = 1;

    ### TCP OPTIMIZATION (mkDefault - can be tuned per machine)

    # Enable TCP Fast Open
    # TCP Fast Open is an extension to the transmission control protocol (TCP) that helps reduce network latency
    # by enabling data to be exchanged during the sender's initial TCP SYN [3].
    # Using the value 3 instead of the default 1 allows TCP Fast Open for both incoming and outgoing connections:
    # https://github.com/CachyOS/CachyOS-Settings/pull/120
    #"net.ipv4.tcp_fastopen" = 3;

    # Bufferbloat mitigations + slight improvement in throughput & latency
    "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr";
    "net.core.default_qdisc" = lib.mkDefault "cake";
    # increase netdev receive queue higher backlog allows the kernel to handle bursts of incoming packets reducing the chance of packet loss
    "net.core.netdev_max_backlog" = lib.mkDefault 4096;
    "net.ipv4.tcp_max_syn_backlog" = lib.mkDefault 8192;
    # defines the maximum ancillary buffer size allowed per socket
    "net.core.optmem_max" = lib.mkDefault 65536;
    # increase the default and maximum buffer sizes which can enhance performance for high-throughput connections
    "net.core.rmem_default" = lib.mkDefault 1048576;
    "net.core.rmem_max" = lib.mkDefault 16777216;
    "net.ipv4.tcp_rmem" = lib.mkDefault "4096 1048576 2097152";
    "net.core.wmem_default" = lib.mkDefault 1048576;
    "net.core.wmem_max" = lib.mkDefault 16777216;
    "net.ipv4.tcp_wmem" = lib.mkDefault "4096 65536 16777216";
    "net.ipv4.udp_rmem_min" = lib.mkDefault 8192;
    "net.ipv4.udp_wmem_min" = lib.mkDefault 8192;
    # enables TCP to detect the path MTU reducing fragmentation
    "net.ipv4.tcp_mtu_probing" = lib.mkDefault 1;
  };
}
