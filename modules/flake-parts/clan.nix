{
  self,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.clan-core.flakeModules.default ];

  # register each clan-services/<svc>/default.nix as clan.modules.<svc>
  clan.modules = lib.mapAttrs (
    name: _: import (self.outPath + "/clan-services/${name}") { inherit self; }
  ) (lib.filterAttrs (_: t: t == "directory") (builtins.readDir (self.outPath + "/clan-services")));
}
