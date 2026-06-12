{
  flake.modules.nixos.workstation =
    { lib, ... }:
    {
      # gvfs: network shares/MTP/trash for non-kde file managers
      services.gvfs.enable = lib.mkDefault true;

      # gnome-disks - disk management GUI (uses gvfs/udisks)
      programs.gnome-disks.enable = lib.mkDefault true;
    };
}
