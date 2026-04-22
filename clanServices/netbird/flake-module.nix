{ self, ... }:
{
  clan.modules.netbird = import ./default.nix { inherit self; };
}
