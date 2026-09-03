{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "opensoho";
  version = "0.15.1";

  src = fetchFromGitHub {
    owner = "rubenbe";
    repo = "opensoho";
    tag = "v${finalAttrs.version}";
    hash = "sha256-fCP+w+kEgLNRMFlVHyBvj4EonaBPqsh4VFrDQJE3LaA=";
  };

  vendorHash = "sha256-Z4BoY75bS6gErSnUGnegYS1roppWxkpmgZ4nTR1y2zk=";

  subPackages = [ "." ];

  env.CGO_ENABLED = 0;

  # tests build pocketbase tests.TestApp, whose data fixtures vendoring omits
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/rubenbe/pocketbase.Version=${finalAttrs.version}"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "OpenWISP-compatible controller for small OpenWRT networks";
    homepage = "https://github.com/rubenbe/opensoho";
    changelog = "https://github.com/rubenbe/opensoho/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "opensoho";
  };
})
