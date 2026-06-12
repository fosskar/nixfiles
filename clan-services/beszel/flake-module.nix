{ self, ... }:
{
  clan.modules.beszel = import ./default.nix { inherit self; };
}
