{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "opensoho";
  version = "0.16.0";

  src = fetchFromGitHub {
    owner = "rubenbe";
    repo = "opensoho";
    tag = "v${finalAttrs.version}";
    hash = "sha256-J+n0cBpDvDsLy21ovWmS8necw1Iyc1gP2cXJKFobnwA=";
  };

  vendorHash = "sha256-0a9OSz7U28vLkNyT4FD8WhLo/A2PYYDE9XpmK3LfPd8=";

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
