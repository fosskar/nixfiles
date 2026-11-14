# TestResolver hardcodes gzip output sizes that go 1.27 no longer produces.
# nixpkgs skips it since https://redirect.github.com/NixOS/nixpkgs/pull/586449
{ inputs, ... }:
_final: prev:
let
  skip = "-skip=^TestResolver$";
in
{
  pmtiles =
    if builtins.elem skip (prev.pmtiles.checkFlags or [ ]) then
      inputs.nixpkgs.lib.warn "nixpkgs pmtiles skips TestResolver, overlays/pmtiles.nix can be removed" prev.pmtiles
    else
      prev.pmtiles.overrideAttrs (old: {
        checkFlags = (old.checkFlags or [ ]) ++ [ skip ];
      });
}
