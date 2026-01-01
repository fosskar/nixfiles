{ config, ... }:
{
  home.shell = {
    enableShellIntegration = true;
    enableZshIntegration = config.programs.zsh.enable;
    enableNushellIntegration = config.programs.nushell.enable;
    enableIonIntegration = config.programs.ion.enable;
    enableFishIntegration = config.programs.fish.enable;
    enableBashIntegration = config.programs.bash.enable;
  };
}
