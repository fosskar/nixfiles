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
          UpdateHostKeys = "yes";
          StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };
}
