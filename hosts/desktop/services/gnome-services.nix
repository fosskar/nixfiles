{ pkgs, ... }:
{
  services = {

    dbus.packages = with pkgs; [
      gcr
    ];

    gnome.gnome-keyring.enable = true;

    gvfs.enable = true;
  };
  programs.gnome-disks.enable = true;
}
