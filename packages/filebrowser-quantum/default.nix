{
  lib,
  fetchFromGitHub,
  buildGoModule,
  buildNpmPackage,
}:

let
  version = "1.1.2-stable";

  src = fetchFromGitHub {
    owner = "gtsteffaniak";
    repo = "filebrowser";
    tag = "v${version}";
    hash = "sha256-WUYfl4mUyAK5Z+Yjrde0qmLBVh/JZslIk/oBVAF3lgk=";
  };

  frontend = buildNpmPackage {
    pname = "filebrowser-quantum-frontend";
    inherit version src;

    sourceRoot = "${src.name}/frontend";
    npmDepsHash = "sha256-MVpITFYnmBJngd3+zEIfoljwUgjjjjLvt5N3R+8apgk=";

    buildPhase = ''
      runHook preBuild

      npm run build:docker

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r dist/* $out

      runHook postInstall
    '';
  };

in
buildGoModule {
  pname = "filebrowser-quantum";
  inherit version src;

  sourceRoot = "${src.name}/backend";

  vendorHash = "sha256-j7zNwkW9EBzmzVLmENTkmxSaokdxsTxdI3CkTEMhnG4=";

  preBuild = ''
    mkdir -p http/embed
    cp -r ${frontend}/* http/embed/
  '';

  postInstall = ''
    mv $out/bin/backend $out/bin/filebrowser-quantum
  '';

  ldflags = [
    "-w"
    "-s"
    "-X github.com/gtsteffaniak/filebrowser/backend/common/version.CommitSHA=v${version}"
    "-X github.com/gtsteffaniak/filebrowser/backend/common/version.Version=v${version}"
  ];

  meta = {
    description = "Access and manage your files from the web";
    homepage = "https://github.com/gtsteffaniak/filebrowser";
    changelog = "https://github.com/gtsteffaniak/filebrowser/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "filebrowser-quantum";
  };
}
