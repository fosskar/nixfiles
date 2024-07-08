{ ... }:
{
  imports = [ ../../../modules/home-manager/podman/podman.nix ];

  services.podman = {
    enable = true;
  };
}
