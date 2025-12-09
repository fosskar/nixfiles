{ lib, ... }:
{
  # common openssh settings for all machines
  services.openssh = {
    enable = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
    settings = {
      X11Forwarding = lib.mkDefault false;
      KbdInteractiveAuthentication = lib.mkDefault false;
      UseDns = lib.mkDefault false;
      StreamLocalBindUnlink = lib.mkDefault true;
      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group18-sha512"
        "diffie-hellman-group16-sha512"
      ];
    };
  };
}
