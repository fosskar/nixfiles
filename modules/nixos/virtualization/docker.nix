{
  flake.modules.nixos.docker =
    {
      config,
      lib,
      self,
      ...
    }:
    {
      imports = [ self.modules.nixos.containers ];

      users.groups.docker.members = lib.mkAfter config.users.groups.wheel.members;
      virtualisation.docker.enable = true;
    };
}
