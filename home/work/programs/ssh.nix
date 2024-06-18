{ config, ... }:
{
  programs.ssh = {
    enable = true;
    includes = [ "${config.home.homeDirectory}/.ssh/extra_config" ];
    extraConfig = ''
      Host gitlab.com
        User git
        IdentityFile ${config.home.homeDirectory}/.ssh/id_rsa
    '';
  };
}
