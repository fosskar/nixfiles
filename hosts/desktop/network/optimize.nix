_: {
  boot = {
    kernel.sysctl = {
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
      # yeah i am still no router do not advertise
      "net.ipv6.conf.default.accept_ra" = 0;
      "net.ipv6.conf.all.accept_ra" = 0;

      # TCP optimization
      # Enable TCP Fast Open
      # TCP Fast Open is an extension to the transmission control protocol (TCP) that helps reduce network latency
      # by enabling data to be exchanged during the sender’s initial TCP SYN [3].
      # Using the value 3 instead of the default 1 allows TCP Fast Open for both incoming and outgoing connections:
      # https://github.com/CachyOS/CachyOS-Settings/pull/120
      #"net.ipv4.tcp_fastopen" = 3;

      # Bufferbloat mitigations + slight improvement in throughput & latency
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "cake";
      # increase netdev receive queue higher backlog allows the kernel to handle bursts of incoming packets reducing the chance of packet loss
      "net.core.netdev_max_backlog" = 4096;
      "net.ipv4.tcp_max_syn_backlog" = 8192;
      # defines the maximum ancillary buffer size allowed per socket
      "net.core.optmem_max" = 65536;
      # increase the default and maximum buffer sizes which can enhance performance for high-throughput connections
      "net.core.rmem_default" = 1048576;
      "net.core.rmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
      "net.core.wmem_default" = 1048576;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.udp_rmem_min" = 8192;
      "net.ipv4.udp_wmem_min" = 8192;
      # enables TCP to detect the path MTU reducing fragmentation
      "net.ipv4.tcp_mtu_probing" = 1;
    };
  };
}
