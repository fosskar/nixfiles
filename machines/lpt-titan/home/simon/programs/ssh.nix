{ config, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "${config.home.homeDirectory}/.ssh/extra_config" ];
    extraConfig = '''';
    #matchBlocks."*" = {
    #  addKeysToAgent = "yes";
    #};
    matchBlocks."git" = {
      host = "github.com gitlab.com";
      user = "git";
      identityFile = "${config.home.homeDirectory}/.ssh/id_rsa";
    };
  };
  services.ssh-agent.enable = true;
  #home.sessionVariables = {
  #  ANSIBLE_SSH_COMMON_ARGS = "-o ProxyCommand='${pkgs.netcat-openbsd}/bin/nc -X 5 -x http://localhost:1080 %h %p'";
  #};
}
