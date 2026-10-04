{ inputs, ... }:
{
  # deploys never force service manifests, so an invalid manifest only
  # surfaces in clan-app or `clan select`; force them here instead
  perSystem =
    { lib, pkgs, ... }:
    {
      checks.clan-service-manifests =
        let
          invalid = lib.concatLists (
            lib.mapAttrsToList (
              source: modules:
              lib.mapAttrsToList (name: _: "${source}/${name}") (
                lib.filterAttrs (
                  _: module: !(builtins.tryEval (builtins.deepSeq module.manifest true)).success
                ) modules
              )
            ) inputs.self.clan.clanInternals.inventoryClass.modulesPerSource
          );
        in
        if invalid == [ ] then
          pkgs.emptyFile
        else
          throw "invalid clan service manifests: ${lib.concatStringsSep ", " invalid}";
    };
}
