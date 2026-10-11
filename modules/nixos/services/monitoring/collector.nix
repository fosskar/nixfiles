{
  # cross-host collector: pull grafana dashboards and alert rules declared on
  # OTHER machines into this (the grafana) host. local ones are already
  # present; this only adds remote ones. self is excluded to avoid feeding our
  # own output back in (infinite recursion). duplicates are collapsed by the
  # options' apply (see grafana.nix).
  flake.modules.nixos.grafana =
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
      remoteProvision = map (h: h.config.services.grafana.provision) remote;
    in
    {
      services.grafana.provision = {
        dashboards.settings.providers = concatMap (
          p: if p.dashboards.settings == null then [ ] else p.dashboards.settings.providers
        ) remoteProvision;
        alerting.rules.settings.groups = concatMap (
          p: if p.alerting.rules.settings == null then [ ] else p.alerting.rules.settings.groups
        ) remoteProvision;
      };
    };
}
