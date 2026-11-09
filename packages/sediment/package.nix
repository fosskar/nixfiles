{
  lib,
  rustPlatform,
  fetchFromGitHub,
  protobuf,
  pkg-config,
  zstd,
  oniguruma,
  sqlite,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "sediment";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "rendro";
    repo = "sediment";
    tag = "v${version}";
    hash = "sha256-hINSwWJE9/Nq5QT2Y7vgFlrwz4fGVYhT4f98Eb7CS2c=";
  };

  # copied from pi-pack; keeps the project id config out of every repo as .sediment/
  patches = [ ./central-project-config.patch ];

  cargoHash = "sha256-NfXChnMYyNyyT3ocdT65Ic6Iu3Zp0LtuTR/Je8FzqZc=";

  nativeBuildInputs = [
    protobuf
    pkg-config
  ];

  buildInputs = [
    oniguruma
    sqlite
    zstd
  ];

  env = {
    PROTOC = "${protobuf}/bin/protoc";
    PROTOC_INCLUDE = "${protobuf}/include";
  };

  # tests require network access for embedding model downloads
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Semantic memory for AI agents - local-first, MCP-native";
    homepage = "https://github.com/rendro/sediment";
    license = lib.licenses.mit;
    mainProgram = "sediment";
  };
}
