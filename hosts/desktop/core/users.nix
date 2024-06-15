{pkgs, ...}: {
  users.users.simon = {
    initialPassword = "123";
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
      "corectrl"
      "gamemode" # https://nixos.wiki/wiki/Gamemode#Known_Errors
      "input"
      "networkmanager"
      "video"
      "wheel"
    ];
  };
}
