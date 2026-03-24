{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "netbird-proxy";
  version = "0.67.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "netbird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5Q90bEAXTnvkEHcsheohu9wdwZRFIoLnqBNzjotFz54=";
  };

  vendorHash = "sha256-6qYS2jXjfPczAfv+g79JsTcEJR9FniAVjW52Yi/g42M=";

  subPackages = [ "proxy/cmd/proxy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/netbirdio/netbird/version.version=${finalAttrs.version}"
    "-X main.builtBy=nix"
  ];

  # needs network access
  doCheck = false;

  postInstall = ''
    mv $out/bin/proxy $out/bin/netbird-proxy
  '';

  meta = {
    homepage = "https://netbird.io";
    description = "NetBird reverse proxy - expose internal services to the public internet through the NetBird network";
    license = lib.licenses.agpl3Only;
    mainProgram = "netbird-proxy";
  };
})
