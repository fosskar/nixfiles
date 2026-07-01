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
  pname = "update-packages";
  version = "0.1.0";
  pyproject = false;

  src = ./updater;

  nativeBuildInputs = [ makeWrapper ];

  # Pure stdlib; __main__.py adds its own directory to sys.path for the
  # sibling modules, so a plain copy + wrapper is enough.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/update_packages $out/bin
    cp *.py $out/lib/update_packages/

    makeWrapper ${python3}/bin/python3 $out/bin/update-packages \
      --add-flags "$out/lib/update_packages/__main__.py" \
      --prefix PATH : ${
        lib.makeBinPath [
          nix-update
          nix
          git
          openssh
        ]
      } \
      --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"

    runHook postInstall
  '';

  meta = {
    description = "update packages/ third-party sources and open one Codeberg PR per group";
    mainProgram = "update-packages";
  };
}
