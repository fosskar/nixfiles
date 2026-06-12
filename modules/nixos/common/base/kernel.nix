{
  flake.modules.nixos.base = _: {
    boot = {
      kernelParams = [
        # Only allow signed kernel modules - harder to load malicious modules
        "module.sig_enforce=1"

        # make stack-based attacks on the kernel harder
        "randomize_kstack_offset=on"

        # obsolete fixed-address syscalls, ROP target; breaks very old binaries
        "vsyscall=none"

        # panic on kernel oops to stop exploits mid-flight
        "oops=panic"

        # buddy allocator free poisoning
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
  };
}
