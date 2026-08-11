{
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.clan-core.flakeModules.default ];

  clan.modules = config.flake.modules."clan.service";

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
