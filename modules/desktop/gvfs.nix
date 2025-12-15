{ lib, ... }:
{
  # gvfs - virtual filesystem for file managers
  # provides network shares (smb, ftp), MTP (phone), trash support
  # used by nautilus, thunar, pcmanfm, nemo, and others (not dolphin/kde)
  services.gvfs.enable = lib.mkDefault true;

  # gnome-disks - disk management GUI (uses gvfs/udisks)
  programs.gnome-disks.enable = lib.mkDefault true;
}
