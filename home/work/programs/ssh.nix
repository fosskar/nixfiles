{ config, ... }:
{
  programs.ssh = {
    enable = true;
    includes = [ "${config.home.homeDirectory}/.ssh/extra_config" ];
  };
}
