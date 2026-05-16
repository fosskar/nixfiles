{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "netbird-proxy";
  version = "0.71.1";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "netbird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xU2P4COLufGdFrit8+IRn96FT1IJKGQ97R9eGv5cjqU=";
  };

  vendorHash = "sha256-NeZuj9o2yu5di+6jbNqCnAw0fI55GA5Otmr77c08QFc=";

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

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://netbird.io";
    description = "NetBird reverse proxy - expose internal services to the public internet through the NetBird network";
    license = lib.licenses.agpl3Only;
    mainProgram = "netbird-proxy";
  };
})
