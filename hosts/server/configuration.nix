############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
_: {
  imports = [
    ./core
    ./hardware
    ./network
    ./nix
    ./pkgs
    ./programs/dconf.nix
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/less.nix
    ./programs/zsh.nix
    ./secrets
    ./security
    ./services/kubernetes/helm.nix
    ./services/kubernetes/k3s.nix
    ./services/gitlab-runner.nix
    ./services/podman.nix
    ./services/power.nix
    ./services/ssh.nix
    ./services/udev.nix
    #./services/vms.nix
    ./services/zram.nix
  ];

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
