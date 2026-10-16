{
  lib,
  opencloud,
  nodejs,
  makeWrapper,
}:
# yjs relay for collaborative editing; lives in the opencloud web repo, so
# reuse that derivation's src and pnpm deps and deploy only this workspace
opencloud.web.overrideAttrs (prevAttrs: {
  pname = "opencloud-yjs";

  nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ makeWrapper ];

  buildPhase = ''
    runHook preBuild
    pnpm deploy --filter=opencloud-yjs-server --prod --offline --config.inject-workspace-packages=true deploy
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin
    cp -r deploy $out/lib/opencloud-yjs
    makeWrapper ${lib.getExe nodejs} $out/bin/opencloud-yjs \
      --add-flags $out/lib/opencloud-yjs/src/server.ts
    runHook postInstall
  '';

  passthru = { };

  meta = prevAttrs.meta // {
    description = "Yjs collaboration server (Hocuspocus) for OpenCloud Web";
    homepage = "https://github.com/opencloud-eu/web/tree/main/services/yjs";
    mainProgram = "opencloud-yjs";
  };
})
