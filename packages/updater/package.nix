{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  nix-update,
  nix,
  git,
  jq,
  openssh,
  cacert,
  coreutils,
}:
stdenvNoCC.mkDerivation {
  pname = "updater";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      (lib.fileset.fileFilter (f: f.hasExt "py") ./.)
      ./effect.sh
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ${python3}/bin/python3 -m unittest discover -s . -v
    runHook postCheck
  '';

  nativeCheckInputs = [ git ];

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

    install -Dm755 effect.sh $out/bin/updater-effect
    wrapProgram $out/bin/updater-effect \
      --prefix PATH : $out/bin:${
        lib.makeBinPath [
          coreutils
          git
          jq
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "update packages/ and flake inputs, one pull request per unit on Codeberg or GitHub";
    mainProgram = "updater-packages";
  };
}
