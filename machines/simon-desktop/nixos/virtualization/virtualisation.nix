{ config, ... }:
{
  # add wheel users to container groups
  users.groups.docker.members = config.users.groups.wheel.members;
  users.groups.podman.members = config.users.groups.wheel.members;

  virtualisation = {
    #libvirtd = {
    #  enable = false;
    #  qemu = {
    #    package = pkgs.qemu_kvm;
    #    runAsRoot = true;
    #  };
    #};

    docker.enable = true;

    podman = {
      enable = true;
      dockerCompat = false;
    };
  };
}
