_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "no";
        extraOptions = {
          UpdateHostKeys = "yes";
        };
      };
    };
  };
}
