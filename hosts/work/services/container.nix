{ pkgs, ... }:
{
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = false;
      autoPrune.enable = true;
      enableNvidia = true;
    };
    docker = {
      #enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      enableNvidia = true;
      autoPrune.enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    dive
    podman-tui
  ];
  #environment.variables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/docker.sock";
}
