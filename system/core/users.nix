{pkgs, ...}: {
  users = {
    groups.simon.gid = 1000;
    users = {
      simon = {
        initialPassword = "123";
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [
          "audio"
          "corectrl"
          "gamemode"
          "networkmanager"
          "video"
          "wheel"
        ];
      };
    };
    defaultUserShell = pkgs.zsh;
  };
}
