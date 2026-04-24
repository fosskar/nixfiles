{
  flake.modules.nixos.gaming =
    { lib, config, ... }:
    {
      # ntsync for wine/proton (star citizen etc)
      boot.kernelModules =
        lib.optionals (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14")
          [ "ntsync" ];

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

      services.udev.extraRules = ''
        # ntsync for wine/proton
        KERNEL=="ntsync", MODE="0644"

        # PS4 controller
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:05C4.*", MODE="0666"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:09CC.*", MODE="0666"
      '';
    };
}
