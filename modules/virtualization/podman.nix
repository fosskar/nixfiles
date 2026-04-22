{
  flake.modules.nixos.podman =
    { config, pkgs, ... }:
    {
      users.groups.podman.members = config.users.groups.wheel.members;
      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
      };
      environment.systemPackages = [
        pkgs.dive
        pkgs.podman-tui
      ];
    };
}
