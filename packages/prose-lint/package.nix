{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  runCommand,
}:
let
  testSrc = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./test_prose_lint.py
      ./fixtures
    ];
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "prose-lint";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./prose_lint.py
      ./rules.toml
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out/share/prose-lint prose_lint.py rules.toml
    makeWrapper ${python3.interpreter} $out/bin/prose-lint \
      --add-flags $out/share/prose-lint/prose_lint.py

    runHook postInstall
  '';

  passthru.tests = {
    unit = runCommand "prose-lint-test-unit" { nativeBuildInputs = [ python3 ]; } ''
      cp ${finalAttrs.finalPackage}/share/prose-lint/* .
      cp -r ${testSrc}/. .
      python3 -m unittest -v test_prose_lint
      touch $out
    '';

    cli =
      runCommand "prose-lint-test-cli"
        {
          nativeBuildInputs = [ finalAttrs.finalPackage ];
        }
        ''
          cd ${testSrc}/fixtures

          prose-lint clean.md clean.nix clean.sh clean.py

          status=0
          prose-lint hits.md hits.nix hits.sh hits.py >"$NIX_BUILD_TOP/hits.out" || status=$?
          [ "$status" -eq 1 ]
          if grep -Ev '^hits\.(md|nix|sh|py):[0-9]+:[0-9]+: [a-z-]+: .+: .+$' "$NIX_BUILD_TOP/hits.out"; then
            exit 1
          fi
          [ "$(wc -l <"$NIX_BUILD_TOP/hits.out")" -eq 18 ]

          status=0
          prose-lint ${finalAttrs.finalPackage}/share/prose-lint/rules.toml || status=$?
          [ "$status" -eq 2 ]

          touch $out
        '';
  };

  meta = {
    description = "flag LLM writing tells in markdown prose and nix, shell and python comments";
    mainProgram = "prose-lint";
  };
})
