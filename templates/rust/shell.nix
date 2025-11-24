{
  callPackage,
  rust-analyzer,
  rustfmt,
  clippy,
  cargo,
  rustc,
}:
let
  mainPkg = callPackage ./default.nix { };
in
mainPkg.overrideAttrs (oa: {
  nativeBuildInputs = [
    # Additional rust tooling
    rust-analyzer
    rustfmt
    clippy
    cargo
    rustc
  ]
  ++ (oa.nativeBuildInputs or [ ]);
})
