{ ... }:
{
  # sabnzbd - usenet download client
  services.sabnzbd = {
    enable = true;
    openFirewall = true; # port 8080
    user = "arr";
    group = "arr";
  };
}
