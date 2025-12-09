_: {
  boot.kernel.sysctl = {
    # Disable NMI watchdog - improves performance and lowers power consumption
    "kernel.nmi_watchdog" = 0;

    # The value controls the tendency of the kernel to reclaim the memory
    # which is used for caching of directory and inode objects (VFS cache).
    # Lowering it from the default value of 100 makes the kernel less inclined
    # to reclaim VFS cache (do not set it to 0, this may produce OOM conditions)
    "vm.vfs_cache_pressure" = 50;

    # Contains, as bytes of total available memory that contains free pages and
    # reclaimable pages, the number of pages at which a process which is generating
    # disk writes will itself start writing out dirty data.
    "vm.dirty_bytes" = 268435456;

    # Contains, as bytes of total available memory that contains free pages and
    # reclaimable pages, the number of pages at which the background kernel flusher
    # threads will start writing out dirty data.
    "vm.dirty_background_bytes" = 67108864;

    # The kernel flusher threads will periodically wake up and write old data
    # out to disk. This tunable expresses the interval between those wakeups,
    # in 100'ths of a second (Default is 500).
    "vm.dirty_writeback_centisecs" = 1500;

    # High precision event timer frequency
    "dev.hpet.max-user-freq" = 3072;

    # bpf JIT for eBPF programs
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 0;

    ### GAMING / LOW LATENCY

    # Scheduler tuning for responsiveness
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;

    # Disable proactive compaction - reduces jitter from THP allocation
    "vm.compaction_proactiveness" = 0;

    # Disable zone reclaim - prevents latency spikes from memory page locking
    "vm.zone_reclaim_mode" = 0;

    # Reduce page lock acquisition latency
    "vm.page_lock_unfairness" = 1;

    # Disable split lock mitigation - improves performance in some games
    "kernel.split_lock_mitigate" = 0;
  };
}
