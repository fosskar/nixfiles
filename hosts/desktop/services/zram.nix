_: {
  # Enable in-memory compressed devices and swap space provided by the zram kernel module.
  # By enable this, we can store more data in memory instead of fallback to disk-based swap devices directly,
  # and thus improve I/O performance when we have a lot of memory.
  #
  #   https://www.kernel.org/doc/Documentation/blockdev/zram.txt
  zramSwap = {
    enable = true;
    # one of "lzo", "lz4", "zstd"
    algorithm = "zstd";
    # Priority of the zram swap devices.
    # It should be a number higher than the priority of your disk-based swap devices
    # (so that the system will fill the zram swap devices before falling back to disk swap).
    priority = 5;
    # Maximum total amount of memory that can be stored in the zram swap devices (as a percentage of your total memory).
    # Defaults to 1/2 of your total RAM. Run zramctl to check how good memory is compressed.
    # This doesn’t define how much memory will be used by the zram swap devices.
    memoryPercent = 50;
  };
  # <https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html>
  # <https://github.com/pop-os/default-settings/pull/163>
  boot.kernel.sysctl = {
    # zram is relatively cheap, prefer swap
    #  swappiness refers to the kernel's willingness prefer swap
    #  over memory. higher values mean that we'll utilize swap more often
    #  which preserves memory, but will cause performance issues as well
    #  as wear on the drive
    "vm.swappiness" = 180; # 0-200
    # level of reclaim when memory is being fragmented
    "vm.watermark_boost_factor" = 0; # 0 to disable
    # aggressiveness of kswapd
    # it defines the amount of memory left in a node/system before kswapd is woken up
    "vm.watermark_scale_factor" = 125; # 0-300
    # zram is in memory, no need to readahead
    # page-cluster refers to the number of pages up to which
    # consecutive pages are read in from swap in a single attempt
    "vm.page-cluster" = 0;
  };
}
