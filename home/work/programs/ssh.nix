{ config, ... }:
{
  programs.ssh = {
    enable = true;
    includes = [ "${config.home.homeDirectory}/.ssh/extra_config" ];
    extraConfig = '''';
    matchBlocks."git" = {
      host = "github.com gitlab.com";
      identityFile = [ "${config.home.homeDirectory}/.ssh/id_rsa.pub" ];
    };
  };
}
