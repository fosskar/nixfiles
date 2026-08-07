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

  # clan validates manifest.exports.out against this registry, and ships only
  # its own core traits. hermes publishes the server loopback port its client
  # role dials, which none of the core traits models
  clan.exportInterfaces.dashboard =
    { lib, ... }:
    {
      options.port = lib.mkOption {
        type = lib.types.port;
        description = "loopback port on the server that forwards to the agent dashboard.";
      };
    };
}
