{ lib, ... }:
{
  # SSD/NVMe TRIM - only runs on filesystems that support it
  services.fstrim = {
    enable = lib.mkDefault true;
    interval = lib.mkDefault "weekly";
  };
}
