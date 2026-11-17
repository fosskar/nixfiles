{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:
let
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "BaaRai";
    repo = "ARTEX";
    tag = "v${version}";
    hash = "sha256-ZO4vGy8UBdowN60zxblr1T//gR38MJGGnwFDCfmmtRk=";
  };

  frontend = buildNpmPackage {
    pname = "artex-frontend";
    inherit version src;
    sourceRoot = "${src.name}/web";
    npmDepsHash = "sha256-wdufWiTWUJsxIrn/q8qJe5JNDj0RMmVQi5M9SzIX+7Y=";
    npmBuildScript = "build:static";
    installPhase = ''
      runHook preInstall
      cp -r out $out
      runHook postInstall
    '';
  };
in
buildGoModule (_finalAttrs: {
  pname = "artex";
  inherit version src;

  vendorHash = "sha256-mej2ZyM540OihKY0Tr3wA6jkUEjgK2ciUSsg/ZESMIU=";

  subPackages = [ "cmd/artex" ];

  env.CGO_ENABLED = 0;

  tags = [ "embedui" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # server/webui_embed.go embeds webui/dist under the embedui tag
  preBuild = ''
    mkdir -p server/webui
    cp -r ${frontend} server/webui/dist
  '';

  overrideModAttrs = _: { preBuild = null; };

  # config.BaseDir() is the binary's directory, read-only in the store; callers
  # set -data, ARTEX_SKILL_DIR and ARTEX_JWT_KEY_DIR to writable paths
  postInstall = ''
    mkdir -p $out/share/artex
    cp -r skills config.example.json $out/share/artex/
  '';

  passthru = {
    inherit frontend;
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "frontend"
      ];
    };
  };

  meta = {
    description = "Self-hosted LLM-driven multi-agent penetration testing platform";
    homepage = "https://github.com/BaaRai/ARTEX";
    changelog = "https://github.com/BaaRai/ARTEX/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "artex";
  };
})
