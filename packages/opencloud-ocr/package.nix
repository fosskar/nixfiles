{
  lib,
  buildGoModule,
  makeWrapper,
  ocrmypdf,
}:
buildGoModule {
  pname = "opencloud-ocr";
  version = "0.1.0";

  src = ./opencloud-ocr;

  vendorHash = "sha256-hOGpciYrGSbeHrltTWKqm2l3tYdAdtiEjTuCIBcDRns=";

  env.CGO_ENABLED = 0;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/opencloud-ocr --prefix PATH : ${lib.makeBinPath [ ocrmypdf ]}
  '';

  meta = {
    description = "adds a text layer to scanned pdfs uploaded to opencloud";
    license = lib.licenses.mit;
    mainProgram = "opencloud-ocr";
  };
}
