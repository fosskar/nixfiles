{
  flake.modules.nixos.containers = _: {
    virtualisation.containers = {
      enable = true;
      registries.search = [
        "docker.io"
        "ghcr.io"
        "quay.io"
      ];
    };
  };
}
