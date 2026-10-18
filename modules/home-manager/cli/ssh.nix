_: {
  flake.modules.homeManager.ssh = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        AddKeysToAgent = "no";
        ControlMaster = "auto";
        # not /tmp: another uid could pre-create the socket and act as the master
        ControlPath = "~/.ssh/cm-%C";
        ControlPersist = "10m";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        Compression = true;
        # FIXME: work around gpg-agent smartcard signing failures with hostbound pubkey auth
        PubkeyAuthentication = "unbound";
        UpdateHostKeys = "yes";
        StrictHostKeyChecking = "accept-new";
      };
    };
  };
}
