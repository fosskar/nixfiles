{
  flake.modules.nixos.podman =
    {
      config,
      lib,
      pkgs,
      self,
      ...
    }:
    {
      imports = [ self.modules.nixos.containers ];

      users.groups.podman.members = lib.mkAfter config.users.groups.wheel.members;
      virtualisation.podman = {
        enable = true;
        dockerCompat = !config.virtualisation.docker.enable;
        dockerSocket.enable = !config.virtualisation.docker.enable;
        defaultNetwork.settings.dns_enabled = true;
      };
      environment.systemPackages = [
        pkgs.dive
        pkgs.podman-tui
      ];
    };
}
