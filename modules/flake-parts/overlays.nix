{ withSystem, ... }:
{
  # local packages (config.packages) -> pkgs.local.*
  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:
      {
        local = config.packages;
      }
    );
}
