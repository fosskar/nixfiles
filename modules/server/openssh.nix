_: {
  # hardened ssh for servers - no password auth
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      X11Forwarding = false;
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      UseDns = false;
      StreamLocalBindUnlink = true;

      # use key exchange algorithms recommended by `nixpkgs#ssh-audit`
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
