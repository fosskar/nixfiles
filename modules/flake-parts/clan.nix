{
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.clan-core.flakeModules.default ];

  clan.modules = config.flake.modules."clan.service";
}
