{ lib, ... }:
{
  boot.kernel.sysctl = {
    # memory overcommit for Redis, etc.
    "vm.overcommit_memory" = lib.mkDefault "1";

    # higher inotify limits for servers
    "fs.inotify.max_user_watches" = lib.mkForce 1048576;
    "fs.inotify.max_user_instances" = lib.mkForce 1024;
    "fs.inotify.max_queued_events" = lib.mkForce 32768;

    # forwarding (servers may act as routers/gateways)
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # additional TCP hardening for servers
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_timestamps" = 0;

    # TCP Fast Open enabled for servers (incoming and outgoing)
    "net.ipv4.tcp_fastopen" = 3;

    # bridge netfilter for containers
    "net.bridge.bridge-nf-call-iptables" = 1;

    # server-specific network buffers
    "net.core.somaxconn" = 32768;
    "net.ipv4.ip_local_port_range" = "32768 65535";
    "net.ipv4.tcp_max_tw_buckets" = 2000000;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;

    # connection tracking
    "net.netfilter.nf_conntrack_generic_timeout" = 60;
    "net.netfilter.nf_conntrack_max" = 1048576;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 600;
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 1;

    # neighbor cache
    "net.ipv4.neigh.default.gc_thresh1" = 4096;
    "net.ipv4.neigh.default.gc_thresh2" = 6144;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;
    "net.ipv4.neigh.default.gc_interval" = 60;
    "net.ipv4.neigh.default.gc_stale_time" = 120;
  };
}
