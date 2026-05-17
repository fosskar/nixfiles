{
  flake.modules.nixos.workstation = _: {
    security = {
      # Required by podman to run containers in rootless mode.
      unprivilegedUsernsClone = true;
    };
  };
}
