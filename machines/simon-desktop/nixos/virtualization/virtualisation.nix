_: {
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
