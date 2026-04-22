{ self, ... }:
{
  clan.modules.harmonia = import ./default.nix { inherit self; };
}
