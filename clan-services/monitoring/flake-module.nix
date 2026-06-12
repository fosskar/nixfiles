{ self, ... }:
{
  clan.modules.monitoring = import ./default.nix { inherit self; };
}
