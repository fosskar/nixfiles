{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "netbird-proxy";
  version = "0.79.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "netbird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Bi83uh8VKvFGUY+AxP34VCXYxpZI1C/oOa6eHmKXpDw=";
  };

  vendorHash = "sha256-+JwuUz8msyoiPUTz8cH3vn9DrvLp6gaM2NqFuTOcRdg=";
  proxyVendor = true;

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
