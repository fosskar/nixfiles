_: {
  boot = {
    kernel.sysctl = {
      # This is required due to some games being unable to reuse their TCP ports
      # if they're killed and restarted quickly - the default timeout is too large.
      "net.ipv4.tcp_fin_timeout" = 5;

      ### PERFORMANCE
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      # increasing is good for gaming USE MAX_INT
      "vm.max_map_count" = 2147483642;
      "fs.file-max" = 2097152;
      # Proactive compaction for (Transparent) Hugepage allocation reduces the average but not necessarily the maximum allocation stalls. Disable proactive compaction because it introduces jitter according to kernel documentation (inner workings):
      "vm.compaction_proactiveness" = 0;
      # If you have enough free RAM increase the number of minimum free Kilobytes to avoid stalls on memory allocations: [5][6]. Do not set this below 1024 KB or above 5% of your systems memory. Reserving 1GB:
      "vm.min_free_kbytes" = 1048576;
      # Disable zone reclaim (locking and moving memory pages that introduces latency spikes)
      "vm.zone_reclaim_mode" = 0;
      # Reduce the maximum page lock acquisition latency while retaining adequate throughput [13][14][15]:
      "vm.page_lock_unfairness" = 1;
      # In some cases, split lock mitigate can slow down performance in some applications and games.
      "kernel.split_lock_mitigate" = 0;
    };
  };
  systemd.services.set-rtc-max-user-freq = {
    description = "Set RTC max user frequency";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "/bin/sh -c 'echo 3072 > /sys/class/rtc/rtc0/max_user_freq'";
      Type = "oneshot";
    };
  };
}
