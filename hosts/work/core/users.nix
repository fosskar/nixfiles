{ config, pkgs, ... }:
{
  users.users.simon = {
    initialPassword = "123";
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "video"
      "wheel"
    ];
  };
}
