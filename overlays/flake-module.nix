{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  flake.overlays = {
    custom = import ./custom-pkgs;
    stable = import ./stable-pkgs { inherit inputs; };
    master = import ./master-pkgs { inherit inputs; };
    tuned-minimal = import ./tuned-minimal;
    llm-agents = inputs.llm-agents.overlays.default;

    # fix stale ocrmypdf paths.patch in current nixpkgs
    ocrmypdf-fix =
      final: prev:
      let
        fixedPatch = final.replaceVars ./custom-pkgs/ocrmypdf-paths.patch {
          gs = lib.getExe final.ghostscript_headless;
          jbig2 = lib.getExe final.jbig2enc;
          pngquant = lib.getExe final.pngquant;
          tesseract = lib.getExe final.tesseract;
          unpaper = lib.getExe final.unpaper;
        };
        fixOcrmypdf = _: pyPrev: {
          ocrmypdf = pyPrev.ocrmypdf.overrideAttrs (old: {
            patches = map (p: if lib.hasSuffix "-paths.patch" (toString p) then fixedPatch else p) old.patches;
          });
        };
        overridePython =
          py:
          py.override {
            packageOverrides = fixOcrmypdf;
          };
        python3 = overridePython prev.python3;
        python313 = overridePython prev.python313;
      in
      {
        inherit python3;
        inherit python313;
        python3Packages = python3.pkgs;
        python313Packages = python313.pkgs;
        ocrmypdf = python3.pkgs.toPythonApplication python3.pkgs.ocrmypdf;
      };

    # default = all overlays combined
    default = lib.composeManyExtensions [
      self.overlays.custom
      self.overlays.stable
      self.overlays.master
      self.overlays.tuned-minimal
      self.overlays.llm-agents
      self.overlays.ocrmypdf-fix
    ];
  };
}
