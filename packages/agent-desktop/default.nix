{
  lib,
  appimageTools,
  fetchurl,
  nodejs,
  runCommand,
  makeWrapper,
}:
let
  pname = "agent-desktop";
  version = "0.15.0";

  src = fetchurl {
    url = "https://github.com/BaLaurent/agent-desktop/releases/download/v${version}/agent-desktop-${version}-x86_64.AppImage";
    hash = "sha256-KO1SNF/F8b8SM/bVEODrJE+JHh7d0hTcgVjwy4ANK4g=";
  };

  extracted = appimageTools.extractType2 { inherit pname version src; };

  # ajv + deps — missing from upstream bundle, required by pi-coding-agent
  ajvTar = fetchurl {
    url = "https://registry.npmjs.org/ajv/-/ajv-8.17.1.tgz";
    hash = "sha256-8J2ueLjMmE2/F466kqexm/+eX3yZBQjzrwv48Rh3Awg=";
  };
  fastDeepEqual = fetchurl {
    url = "https://registry.npmjs.org/fast-deep-equal/-/fast-deep-equal-3.1.3.tgz";
    hash = "sha256-sBmgmA8nY43D+Fg2sOR48YjgDXpuWFLAgZ+ob1bke48=";
  };
  fastUri = fetchurl {
    url = "https://registry.npmjs.org/fast-uri/-/fast-uri-3.0.6.tgz";
    hash = "sha256-jHEgRh2rBm8hN5VRhis4D623JOyQxKFJGBB5oFvx6Bw=";
  };
  jsonSchemaTraverse = fetchurl {
    url = "https://registry.npmjs.org/json-schema-traverse/-/json-schema-traverse-1.0.0.tgz";
    hash = "sha256-AjIiYi3yn8J0veXTWQ5Hqh1Kjjwdbiq6AplI7Xl5myE=";
  };
  requireFromString = fetchurl {
    url = "https://registry.npmjs.org/require-from-string/-/require-from-string-2.0.2.tgz";
    hash = "sha256-y2lKSWWQj3d1oMdX8Az05iTRk81x13mI+8yg9Ze4jYI=";
  };

  # patched extracted contents with ajv injected
  patched = runCommand "agent-desktop-${version}-patched" { } ''
    cp -r ${extracted} $out
    chmod -R u+w $out

    for pkg in ajv fast-deep-equal fast-uri json-schema-traverse require-from-string; do
      mkdir -p $out/resources/app/node_modules/$pkg
    done
    tar xzf ${ajvTar} -C $out/resources/app/node_modules/ajv --strip-components=1
    tar xzf ${fastDeepEqual} -C $out/resources/app/node_modules/fast-deep-equal --strip-components=1
    tar xzf ${fastUri} -C $out/resources/app/node_modules/fast-uri --strip-components=1
    tar xzf ${jsonSchemaTraverse} -C $out/resources/app/node_modules/json-schema-traverse --strip-components=1
    tar xzf ${requireFromString} -C $out/resources/app/node_modules/require-from-string --strip-components=1
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = patched;
  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    # desktop file and icons
    install -Dm444 ${patched}/agent-desktop.desktop $out/share/applications/agent-desktop.desktop
    substituteInPlace $out/share/applications/agent-desktop.desktop \
      --replace-quiet "Exec=AppRun" "Exec=agent-desktop"
    cp -r ${patched}/usr/share/icons $out/share/icons 2>/dev/null || true

    # wrap with electron flags + node in PATH
    wrapProgram $out/bin/agent-desktop \
      --prefix PATH : "${nodejs}/bin" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations,UseOzonePlatform" \
      --add-flags "--use-gl=angle" \
      --add-flags "--use-angle=opengl" \
      --add-flags "--enable-wayland-ime"
  '';

  meta = {
    description = "open-source desktop client for Claude AI";
    homepage = "https://github.com/BaLaurent/agent-desktop";
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "agent-desktop";
  };
}
