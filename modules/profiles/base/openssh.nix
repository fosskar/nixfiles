{ lib, ... }:
{
  # srvos sets: X11Forwarding, KbdInteractiveAuthentication, UseDns,
  # StreamLocalBindUnlink, KexAlgorithms, PasswordAuthentication

  services.openssh = {
    enable = true;
    openFirewall = true;
    # socket activation - srvos doesn't set this
    startWhenNeeded = lib.mkDefault true;
  };
}
