_: {
  virtualisation = {
    containers.cdi.dynamic.nvidia.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = false;
      autoPrune.enable = true;
    };
    docker = {
      enable = true;
      enableNvidia = true;
      autoPrune.enable = true;
    };
  };
}
