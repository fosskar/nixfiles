{ pkgs, ... }:
{
  services = {
    # add some drivers for common printers
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
      ];
    };
    # required for network discovery of printers
    avahi = {
      enable = false;
      # resolve .local domains for printers
      nssmdns4 = true;
      # pass avahi port(s) to the firewall
      openFirewall = true;
    };
  };
}
