{ self, ... }:
{
  clan.modules.ups = import ./default.nix { inherit self; };
}
