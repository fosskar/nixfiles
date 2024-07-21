{ ... }:
{
  services = {
    resolved = {
      # enable systemd DNS resolver daemon
      enable = true;

      dnssec = "allow-downgrade";

      dnsovertls = "opportunistic";
      # ideally our fallbackDns should be something more widely available
      # but I do not want my last resort to sell my data to every company available
      # NOTE: DNS fallback is not a recovery DNS
      # See <https://github.com/systemd/systemd/issues/5771#issuecomment-296673115>
      fallbackDns = [ "9.9.9.9" ];
    };
  };
}
