{ lib, ... }:
{
  # zram - compressed swap in RAM
  # stores more data in memory instead of falling back to disk swap
  # improves I/O performance when memory pressure is high
  # https://www.kernel.org/doc/Documentation/blockdev/zram.txt
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd"; # lzo, lz4, or zstd
    # higher than disk swap so zram fills first
    priority = lib.mkDefault 5;
    # max memory for zram (percentage of total RAM)
    # run `zramctl` to check compression ratio
    memoryPercent = lib.mkDefault 25;
  };

  # sysctl tuning for zram
  # https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html
  # https://github.com/pop-os/default-settings/pull/163
  boot.kernel.sysctl = {
    # zram is cheap, prefer swap over killing processes
    "vm.swappiness" = lib.mkDefault 100;
    # disable watermark boosting (not needed with zram)
    "vm.watermark_boost_factor" = lib.mkDefault 0;
    # wake kswapd earlier
    "vm.watermark_scale_factor" = lib.mkDefault 125;
    # zram is in memory, no readahead needed
    "vm.page-cluster" = lib.mkDefault 0;
  };
}
