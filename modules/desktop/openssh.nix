{ lib, ... }:
{
  # desktop: allow password auth for local network
  services.openssh.settings.PasswordAuthentication = lib.mkDefault true;
}
