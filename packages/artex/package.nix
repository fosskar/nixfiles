{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  makeBinaryWrapper,
  nix-update-script,
  bash,
  bbot,
  coreutils,
  curl,
  dalfox,
  dnsutils,
  ffuf,
  findutils,
  gawk,
  git,
  gnugrep,
  gnused,
  gnutar,
  gzip,
  httpx,
  inetutils,
  iputils,
  jq,
  katana,
  netcat-openbsd,
  nmap,
  nodejs,
  nuclei,
  playwright-mcp,
  procps,
  python3,
  ripgrep,
  sqlmap,
  subfinder,
  unzip,
  wget,
  whois,
  xz,
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

  # the docker image's tool set; norma's bash tool runs worker commands via
  # `bash -c` from PATH
  tools = [
    bash
    bbot
    coreutils
    curl
    dalfox
    dnsutils
    ffuf
    findutils
    gawk
    git
    gnugrep
    gnused
    gnutar
    gzip
    httpx
    inetutils
    iputils
    jq
    katana
    netcat-openbsd
    nmap
    nodejs
    nuclei
    playwright-mcp
    procps
    python3
    ripgrep
    sqlmap
    subfinder
    unzip
    wget
    whois
    xz
  ];
in
buildGoModule (_finalAttrs: {
  pname = "artex";
  inherit version src;

  vendorHash = "sha256-mej2ZyM540OihKY0Tr3wA6jkUEjgK2ciUSsg/ZESMIU=";

  subPackages = [ "cmd/artex" ];

  env.CGO_ENABLED = 0;

  nativeBuildInputs = [ makeBinaryWrapper ];

  # the seeded browser mcp runs `npx @playwright/mcp`, which downloads at
  # runtime; nixpkgs playwright-mcp ships its own chromium
  postPatch = ''
    substituteInPlace db/db.go \
      --replace-fail "VALUES ('browser', 'stdio', 'npx', \$1" "VALUES ('browser', 'stdio', 'playwright-mcp', \$1" \
      --replace-fail '`["@playwright/mcp","--headless"]`' '`["--headless"]`'
  '';

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
    wrapProgram $out/bin/artex --prefix PATH : ${lib.makeBinPath tools}
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
