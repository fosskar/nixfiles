_: {
  boot = {
    kernelParams = [
      # Only allow signed kernel modules - harder to load malicious modules
      "module.sig_enforce=1"

      # make stack-based attacks on the kernel harder
      "randomize_kstack_offset=on"

      # Disable vsyscalls as they are obsolete and have been replaced with vDSO.
      # vsyscalls are also at fixed addresses in memory, making them a potential
      # target for ROP attacks. This breaks really old binaries for security.
      "vsyscall=none"

      # Sometimes certain kernel exploits will cause what is known as an "oops".
      # This parameter will cause the kernel to panic on such oopses, thereby
      # preventing those exploits.
      "oops=panic"

      # enable buddy allocator free poisoning
      #  on: memory will be filled with a specific byte pattern
      #      that is unlikely to occur in normal operation.
      "page_poison=on"

      # performance improvement for direct-mapped memory-side-cache utilization
      # reduces the predictability of page allocations
      "page_alloc.shuffle=1"
    ];

    # obscure network protocols nobody uses
    blacklistedKernelModules = [
      "dccp" # Datagram Congestion Control Protocol
      "sctp" # Stream Control Transmission Protocol
      "rds" # Reliable Datagram Sockets
      "tipc" # Transparent Inter-Process Communication
      "n-hdlc" # High-level Data Link Control
      "netrom" # NetRom
      "x25" # X.25
      "ax25" # Amateur X.25
      "rose" # ROSE
      "decnet" # DECnet
      "econet" # Econet
      "af_802154" # IEEE 802.15.4
      "ipx" # Internetwork Packet Exchange
      "appletalk" # Appletalk
      "psnap" # Subnetwork Access Protocol
      "p8022" # IEEE 802.3
      "p8023" # Novell raw IEEE 802.3
      "can" # Controller Area Network
      "atm" # ATM
    ];
  };
}
