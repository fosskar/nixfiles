_: {
  services = {
    openssh = {
      enable = true;
      settings = {
        #PasswordAuthentication = true;
        #KbdInteractiveAuthentication = false;
        PermitRootLogin = "yes";
        challengeResponseAuthentication = false;
        X11Forwarding = false;
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "sntrup761x25519-sha512@openssh.com"
        ];
      };
      extraConfig = ''
        StreamLocalBindUnlink yes
        AllowTcpForwarding yes
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
      '';
      openFirewall = true;
    };
  };
}
