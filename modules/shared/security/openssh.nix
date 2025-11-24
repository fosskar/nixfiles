_: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      X11Forwarding = false;
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      UseDns = false;
      StreamLocalBindUnlink = true;

      # Use key exchange algorithms recommended by `nixpkgs#ssh-audit`
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "sntrup761x25519-sha512@openssh.com"
      ];
    };
  };
}
