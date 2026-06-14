{
  # cross-host collector: pull gatus checks declared on OTHER machines'
  # services.gatus.settings.endpoints into this (the gatus) host. local checks
  # are already present; this only adds remote ones. self is excluded to avoid
  # feeding our own output back in (infinite recursion).
  flake.modules.nixos.gatus =
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
      services.gatus.settings.endpoints = concatMap (
        h: h.config.services.gatus.settings.endpoints or [ ]
      ) remote;
    };
}
