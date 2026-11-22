{
  flake.modules.nixos.containers = _: {
    virtualisation.containers = {
      enable = true;
      registries.settings.unqualified-search-registries = [
        "docker.io"
        "ghcr.io"
        "quay.io"
      ];
    };
  };
}
