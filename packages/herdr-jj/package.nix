{
  lib,
  buildGoModule,
  makeWrapper,
  jujutsu,
}:
buildGoModule {
  pname = "herdr-jj";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./main.go
      ./herdr-plugin.toml
    ];
  };

  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/herdr-jj --prefix PATH : ${lib.makeBinPath [ jujutsu ]}
    install -Dm444 herdr-plugin.toml -t $out/share/herdr-jj
    substituteInPlace $out/share/herdr-jj/herdr-plugin.toml --replace-fail @out@ $out
  '';

  meta = {
    description = "herdr plugin that shows the nearest jj bookmark in the sidebar";
    license = lib.licenses.mit;
    mainProgram = "herdr-jj";
    platforms = lib.platforms.unix;
  };
}
