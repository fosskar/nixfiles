{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs_24,
  nix-update-script,
}:
buildNpmPackage (finalAttrs: {
  pname = "yuvomi";
  version = "2.71.0";

  src = fetchFromGitHub {
    owner = "ulsklyc";
    repo = "yuvomi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ioBJVOdbPNa65qLWZAWmUZ61bbv3iTKlxgbpn6Vr4FY=";
  };

  npmDepsHash = "sha256-aJ+IKQXzV0yPvlT5IKOMlEcyeD+mjF1WmAtRr16j8Mk=";

  nodejs = nodejs_24;

  # devDependencies are only the browser test tooling (puppeteer, axe-core, sharp)
  npmInstallFlags = [ "--omit=dev" ];

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/yuvomi $out/bin
    cp -r package.json CHANGELOG.md node_modules server public $out/lib/yuvomi/

    makeWrapper ${lib.getExe nodejs_24} $out/bin/yuvomi \
      --add-flags $out/lib/yuvomi/server/index.js \
      --set-default NODE_ENV production \
      --set-default APP_BUILD_REVISION v${finalAttrs.version}

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Self-hosted family planner for tasks, calendars, shopping, meals, and budget";
    homepage = "https://github.com/ulsklyc/yuvomi";
    changelog = "https://github.com/ulsklyc/yuvomi/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "yuvomi";
    platforms = lib.platforms.linux;
  };
})
