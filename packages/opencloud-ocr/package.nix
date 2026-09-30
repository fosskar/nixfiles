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

  vendorHash = "sha256-qZnaU44c+KG42y0YidtIkY3JLyQCabQvPz4hwRZExws=";

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
