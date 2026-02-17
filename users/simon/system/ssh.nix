_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        user = "root";
        addKeysToAgent = "no";
        controlMaster = "auto";
        controlPath = "/tmp/ssh-%u-%r@%h:%p";
        controlPersist = "10m";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = true;
        extraOptions = {
          # FIXME: Work around gpg-agent smartcard signing failures with hostbound pubkey auth.
          PubkeyAuthentication = "unbound";
          UpdateHostKeys = "yes";
          StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };
}
