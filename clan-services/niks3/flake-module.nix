{ self, ... }:
{
  clan.modules.niks3 = import ./default.nix { inherit self; };
}
