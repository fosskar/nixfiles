{
  self,
  lib,
  rootPath,
  inputs,
  ...
}:
{
  imports = [ inputs.clan-core.flakeModules.default ];

  # register each clan-services/<svc>/default.nix as clan.modules.<svc>
  clan.modules = lib.mapAttrs (
    name: _: import (rootPath + "/clan-services/${name}") { inherit self; }
  ) (lib.filterAttrs (_: t: t == "directory") (builtins.readDir (rootPath + "/clan-services")));
}
