_: {
  services = {

    gnome.gnome-keyring.enable = false;

    gvfs.enable = true;
  };
  programs.gnome-disks.enable = true;
}
