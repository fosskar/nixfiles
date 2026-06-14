{
  # cross-host collector: pull homepage tiles declared on OTHER machines'
  # services.homepage-dashboard.serviceGroups into this (the homepage) host.
  # local tiles are already present; this only adds remote ones. self is
  # excluded to avoid feeding our own output back in (infinite recursion).
  flake.modules.nixos.homepage =
    {
      config,
      lib,
      self,
      ...
    }:
    let
      inherit (lib)
        filterAttrs
        attrValues
        zipAttrsWith
        concatLists
        ;
      remote = attrValues (
        filterAttrs (name: _: name != config.networking.hostName) self.nixosConfigurations
      );
    in
    {
      services.homepage-dashboard.serviceGroups = zipAttrsWith (_group: concatLists) (
        map (h: h.config.services.homepage-dashboard.serviceGroups) remote
      );
    };
}
