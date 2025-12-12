_: {
  # common openssh settings for all machines
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      X11Forwarding = false;
      KbdInteractiveAuthentication = false;
      UseDns = false;
      StreamLocalBindUnlink = true;
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
