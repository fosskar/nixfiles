{ pkgs, ... }:
{
  # spare/unused 1TB disk: not in any zpool, never accessed, so hd-idle never
  # spins it down (it only acts on disks that go active->idle). set a drive-level
  # standby timer so it parks itself after ~10min and stops wasting ~5W.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL_SHORT}=="Z9CBK75S", RUN+="${pkgs.hdparm}/bin/hdparm -S 120 /dev/%k"
  '';
}
