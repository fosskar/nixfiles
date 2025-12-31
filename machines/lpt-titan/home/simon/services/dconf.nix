{ pkgs, ... }:
{
  home.packages = [
    pkgs.dconf2nix # <https://github.com/gvolpe/dconf2nix>
  ];

  dconf.settings = {
    # like a global dark switch that some apps respect
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    # tell virt-manager to use system connection
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
