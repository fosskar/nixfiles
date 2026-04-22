{
  flake.modules.nixos.docker =
    { config, ... }:
    {
      users.groups.docker.members = config.users.groups.wheel.members;
      virtualisation.docker.enable = true;
    };
}
