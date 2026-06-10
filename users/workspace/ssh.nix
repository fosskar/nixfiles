_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "no";
      ControlMaster = "auto";
      ControlPath = "/tmp/ssh-%u-%r@%h:%p";
      ControlPersist = "10m";
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
      Compression = true;
      # work around gpg-agent smartcard signing failures with hostbound pubkey
      # auth (simon's forwarded agent, see users/simon/ssh.nix)
      PubkeyAuthentication = "unbound";
      UpdateHostKeys = "yes";
      StrictHostKeyChecking = "accept-new";
    };
  };
}
