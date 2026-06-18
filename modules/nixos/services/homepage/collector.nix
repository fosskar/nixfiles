{
  # cross-host collector: pull homepage tiles declared on OTHER machines'
  # services.homepage-dashboard.services into this (the homepage) host.
  # local tiles are already present; this only adds remote ones. self is
  # excluded to avoid feeding our own output back in (infinite recursion).
  # same-named groups across hosts are collapsed by the option's apply
  # (see homepage.nix).
  flake.modules.nixos.homepage =
    {
      config,
      lib,
      self,
      ...
    }:
    let
      inherit (lib) filterAttrs attrValues concatMap;
      remote = attrValues (
        filterAttrs (name: _: name != config.networking.hostName) self.nixosConfigurations
      );
    in
    {
      services.homepage-dashboard.services = concatMap (
        h: h.config.services.homepage-dashboard.services or [ ]
      ) remote;
    };
}
