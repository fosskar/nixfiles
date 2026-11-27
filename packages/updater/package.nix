{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  nix-update,
  nix,
  git,
  openssh,
  cacert,
  fetchpatch,
}:
let
  # nix 2.35 no longer copies a flake to the store in `nix flake metadata`, so
  # --flake updates fail; drop with the next nix-update release
  # https://redirect.github.com/Mic92/nix-update/pull/698
  nix-update' = nix-update.overridePythonAttrs (old: {
    patches = old.patches or [ ] ++ [
      (fetchpatch {
        url = "https://github.com/Mic92/nix-update/commit/dcef4fdd7edbd9ef83c701e5d92a3df81fbd0e33.patch";
        hash = "sha256-uNOfiYbLAm/0Ret2nUQ3Wxd1IoOsclRbF11z2gGx0vM=";
      })
    ];
    # 100 releases with all their assets exceed what github sends in one
    # response for llama.cpp (IncompleteRead), so the version lookup fails
    postPatch = old.postPatch or "" + ''
      substituteInPlace nix_update/version/github.py \
        --replace-fail "RELEASES_PER_PAGE = 100" "RELEASES_PER_PAGE = 20"
    '';
  });
in
stdenvNoCC.mkDerivation {
  pname = "updater";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (f: f.hasExt "py") ./.;
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
      update_packages.py update_flake_inputs.py update_effect.py \
      $out/lib/updater/

    for entry in update_packages update_flake_inputs update_effect; do
      bin="updater-''${entry#update_}"
      bin="''${bin//_/-}"
      makeWrapper ${python3}/bin/python3 $out/bin/$bin \
        --add-flags "$out/lib/updater/$entry.py" \
        --prefix PATH : ${
          lib.makeBinPath [
            nix-update'
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

  meta = {
    description = "update packages/ and flake inputs, one pull request per unit on GitHub";
    mainProgram = "updater-packages";
  };
}
