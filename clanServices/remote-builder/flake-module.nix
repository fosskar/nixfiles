{ self, ... }:
{
  clan.modules.remote-builder = import ./default.nix { inherit self; };
}
