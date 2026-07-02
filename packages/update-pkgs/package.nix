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
  pname = "update-pkgs";
  version = "0.1.0";
  pyproject = false;

  src = ./updater;

  nativeBuildInputs = [ makeWrapper ];

  checkPhase = ''
    runHook preCheck
    ${python3}/bin/python3 -m unittest discover -s . -v
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/update_pkgs $out/bin
    cp changelog.py forge.py packages.py __main__.py $out/lib/update_pkgs/

    makeWrapper ${python3}/bin/python3 $out/bin/update-pkgs \
      --add-flags "$out/lib/update_pkgs/__main__.py" \
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
    mainProgram = "update-pkgs";
  };
}
