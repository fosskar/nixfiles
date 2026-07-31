_:
# pandas-stubs passes generators to @parametrize; pytest 9.1 turns the resulting
# PytestRemovedIn10Warning into a collection error. upstream nixpkgs pins the old
# hook (already in nixos-unstable-small), drop this once nixos-unstable catches up
_final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
      pandas-stubs = pyPrev.pandas-stubs.override {
        pytestCheckHook = pyFinal.pytest9_0CheckHook;
      };
    })
  ];
}
