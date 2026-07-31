{
  flake.modules.nixos.containers = _: {
    virtualisation.containers = {
      enable = true;
      registries.settings.registries.search.registries = [
        "docker.io"
        "ghcr.io"
        "quay.io"
      ];
    };
  };
}
