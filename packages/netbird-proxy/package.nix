{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "netbird-proxy";
  version = "0.74.7";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "netbird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Rmi54gS1yOlbBYUUit49p5WwnhfwPd/G5Wq209Wdv/4=";
  };

  vendorHash = "sha256-bcz8XaME182Rh346VQhTO5E3hb5WmCIjB1Q6dvOu3iY=";

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
