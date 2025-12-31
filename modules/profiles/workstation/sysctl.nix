_: {
  boot.kernel.sysctl = {
    # disable nmi watchdog - not needed on workstation, saves power
    "kernel.nmi_watchdog" = 0;

    # lower vfs cache pressure - kernel less inclined to reclaim VFS cache
    # (do not set to 0, may cause OOM)
    "vm.vfs_cache_pressure" = 50;

    # dirty page writeback tuning for workstation I/O patterns
    "vm.dirty_bytes" = 268435456;
    "vm.dirty_background_bytes" = 67108864;
    "vm.dirty_writeback_centisecs" = 1500;

    # high precision event timer frequency (audio apps benefit)
    "dev.hpet.max-user-freq" = 3072;

    # bpf JIT for eBPF programs (needed for scx scheduler)
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 0;
  };
}
