{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.gaming;
in
{
  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      # scheduler tuning for responsiveness
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;

      # disable proactive compaction - reduces jitter from THP allocation
      "vm.compaction_proactiveness" = 0;

      # disable zone reclaim - prevents latency spikes from memory page locking
      "vm.zone_reclaim_mode" = 0;

      # reduce page lock acquisition latency
      "vm.page_lock_unfairness" = 1;

      # disable split lock mitigation - improves performance in some games
      "kernel.split_lock_mitigate" = 0;
    };
  };
}
