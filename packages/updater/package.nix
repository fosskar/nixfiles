{
  lib,
  python3,
  makeWrapper,
  nix-update,
  nix,
  git,
  openssh,
  cacert,
}:
python3.pkgs.buildPythonApplication {
  pname = "updater";
  version = "0.1.0";
  pyproject = false;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (f: f.hasExt "py") ./.;
  };

  nativeBuildInputs = [ makeWrapper ];

  checkPhase = ''
    runHook preCheck
    ${python3}/bin/python3 -m unittest discover -s . -v
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/updater $out/bin
    cp changelog.py forge.py packages.py pipeline.py \
      update_packages.py update_flake_inputs.py $out/lib/updater/

    for entry in update_packages update_flake_inputs; do
      bin="updater-''${entry#update_}"
      bin="''${bin//_/-}"
      makeWrapper ${python3}/bin/python3 $out/bin/$bin \
        --add-flags "$out/lib/updater/$entry.py" \
        --prefix PATH : ${
          lib.makeBinPath [
            nix-update
            nix
            git
            openssh
          ]
        } \
        --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
        --set-default PYTHONUNBUFFERED 1
    done

    runHook postInstall
  '';

  # buildPythonApplication injects a default nix-update updateScript;
  # this package is local-only (path src, no fetcher) and cannot be updated.
  passthru.updateScript = null;

  meta = {
    description = "update packages/ and flake inputs, one Codeberg PR per unit";
    mainProgram = "updater-packages";
  };
}
