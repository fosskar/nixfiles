{ ... }:
{
  services.fstrim = {
    enable = true;
    # The timer interval passed to the systemd service. The default is monthly
    # but we prefer trimming weekly as the system receives a lot of writes.
    interval = "weekly";
  };
}
