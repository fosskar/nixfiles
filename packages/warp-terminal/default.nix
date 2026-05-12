{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  makeWrapper,
  writeShellScriptBin,
  cargo-about,
  protobuf,
  openssl,
  alsa-lib,
  expat,
  fontconfig,
  freetype,
  libglvnd,
  libxkbcommon,
  vulkan-loader,
  wayland,
  xdg-utils,
  zenity,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  zlib,
  waylandSupport ? true,
}:

let
  pname = "warp-terminal";
  version = "0.2026.05.06.09.13.preview_00";

  tag = "v${version}";
  linuxArch = if stdenv.hostPlatform.system == "x86_64-linux" then "x86_64" else "aarch64";

  runtimeDependencies = [
    expat
    fontconfig
    freetype
    libglvnd
    libxkbcommon
    stdenv.cc.cc.lib
    vulkan-loader
    xdg-utils
    libx11
    libxcb
    libxcursor
    libxi
    zlib
  ]
  ++ lib.optionals waylandSupport [ wayland ];

  runtimePrograms = [
    xdg-utils
    zenity
  ];

  warpProtoApis = fetchFromGitHub {
    owner = "warpdotdev";
    repo = "warp-proto-apis";
    rev = "02997b8fc6a468783642d93bf1bfa89fb7f42502";
    hash = "sha256-VN7G7V8JHQpMkujogXqEAPYnMKa3wUbpG872tNTY0sw=";
  };

  warpWorkflows = fetchFromGitHub {
    owner = "warpdotdev";
    repo = "workflows";
    rev = "793a98ddda6ef19682aed66364faebd2829f0e01";
    hash = "sha256-ICgkxlUUIfyhr0agZEk3KtGHX0uNRlRCKtz0iF2jd7o=";
  };

  warpChannelConfig = writeShellScriptBin "warp-channel-config" ''
    channel=preview
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --channel)
          channel="$2"
          shift 2
          ;;
        --target-family | --target-os)
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done

    case "$channel" in
      local)
        app_id=dev.warp.WarpLocal
        logfile_name=warp-local.log
        ;;
      dev)
        app_id=dev.warp.WarpDev
        logfile_name=warp-dev.log
        ;;
      preview)
        app_id=dev.warp.WarpPreview
        logfile_name=warp-preview.log
        ;;
      stable | *)
        app_id=dev.warp.Warp
        logfile_name=warp.log
        ;;
    esac

    cat <<EOF
    {
      "app_id": "$app_id",
      "logfile_name": "$logfile_name",
      "server_config": {
        "server_root_url": "https://app.warp.dev",
        "rtc_server_url": "wss://rtc.app.warp.dev/graphql/v2",
        "session_sharing_server_url": "wss://sessions.app.warp.dev",
        "firebase_auth_api_key": "AIzaSyBdy3O3S9hrdayLJxJ7mriBR4qgUaUygAs"
      },
      "oz_config": {
        "oz_root_url": "https://oz.warp.dev",
        "workload_audience_url": null
      },
      "telemetry_config": null,
      "autoupdate_config": null,
      "crash_reporting_config": null,
      "mcp_static_config": null
    }
    EOF
  '';
in
rustPlatform.buildRustPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "warpdotdev";
    repo = "warp";
    rev = tag;
    hash = "sha256-xq8ENCzB1PGUNQ+9BdF1AJhS0U6aABR4FoSgyX/4D20=";
  };

  cargoHash = "sha256-GgOEc1IMUK3nSX0eftFnzs8eQAZeGMXl9WYPCipGuls=";

  nativeBuildInputs = [
    cargo-about
    cmake
    makeWrapper
    warpChannelConfig
    pkg-config
    protobuf
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    alsa-lib
    expat
    fontconfig
    freetype
    openssl
    wayland
    zlib
  ];

  GIT_RELEASE_TAG = tag;
  APPIMAGE_NAME = "Warp-${linuxArch}.AppImage";
  WARP_APP_NAME = "Warp";
  RUSTFLAGS = "-Awarnings";

  postPatch = ''
    patchShebangs script

    substituteInPlace script/prepare_bundled_resources \
      --replace-fail '  cargo about generate \' '  { cargo about generate \' \
      --replace-fail '      "$REPO_ROOT/about.hbs"' '      "$REPO_ROOT/about.hbs"
      } 2> >(grep -v -e "failed to parse license .*GPL-2.0" -e "a deprecated license identifier was used" >&2)'
  '';

  preBuild = ''
    warp_proto_manifest=$(find "$NIX_BUILD_TOP" -path '*/warp_multi_agent_api-0.0.0/build.rs' -print -quit)
    if [ -z "$warp_proto_manifest" ]; then
      echo "could not find vendored warp_multi_agent_api build.rs" >&2
      exit 1
    fi

    warp_proto_vendor=$(dirname "$(dirname "$(dirname "$warp_proto_manifest")")")
    cp ${warpProtoApis}/apis/multi_agent/v1/*.proto "$warp_proto_vendor"/

    warp_workflows_manifest=$(find "$NIX_BUILD_TOP" -path '*/warp-workflows-0.1.0/build.rs' -print -quit)
    if [ -z "$warp_workflows_manifest" ]; then
      echo "could not find vendored warp-workflows build.rs" >&2
      exit 1
    fi

    warp_workflows_vendor=$(dirname "$(dirname "$warp_workflows_manifest")")
    cp -r ${warpWorkflows}/specs "$warp_workflows_vendor"/
  '';

  buildPhase = ''
    runHook preBuild

    cargo build -p warp --profile release-lto --bin preview --bin generate_settings_schema --features release_bundle,crash_reporting,gui,nld_improvements,preview_channel --locked

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 target/release-lto/preview $out/opt/warpdotdev/warp-terminal/warp

    SKIP_SETTINGS_SCHEMA=1 script/prepare_bundled_resources \
      $out/opt/warpdotdev/warp-terminal/resources \
      preview \
      release-lto

    target/release-lto/generate_settings_schema \
      --channel preview \
      $out/opt/warpdotdev/warp-terminal/resources/settings_schema.json

    install -Dm644 app/channels/preview/dev.warp.WarpPreview.desktop \
      $out/share/applications/dev.warp.WarpPreview.desktop

    for size in 16x16 32x32 64x64 128x128 256x256 512x512; do
      icon=app/channels/preview/icon/no-padding/$size.png
      if [ -f "$icon" ]; then
        install -Dm644 "$icon" \
          $out/share/icons/hicolor/$size/apps/dev.warp.WarpPreview.png
      fi
    done

    makeWrapper $out/opt/warpdotdev/warp-terminal/warp $out/bin/warp-terminal \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies} \
      --prefix PATH : ${lib.makeBinPath runtimePrograms} \
      ${lib.optionalString waylandSupport "--set WARP_ENABLE_WAYLAND 1"}

    runHook postInstall
  '';

  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "agentic development environment, born out of the terminal";
    homepage = "https://github.com/warpdotdev/warp";
    license = [
      lib.licenses.agpl3Only
      lib.licenses.mit
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "warp-terminal";
  };
}
