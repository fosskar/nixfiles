{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "opencloud-mcp";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "opencloud-eu";
    repo = "opencloud-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-yevqJN0cQdhE8yOMieIHp8gWxXt5FC/ShVjHj4oOWpo=";
  };

  vendorHash = "sha256-6gkcSYyaD77ckbyAHC2JZiVBW8ZTi1lZbmWlvcZmEbw=";

  subPackages = [ "cmd/opencloud-mcp" ];

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "MCP server for OpenCloud files, acting as one signed-in user";
    homepage = "https://github.com/opencloud-eu/opencloud-mcp";
    changelog = "https://github.com/opencloud-eu/opencloud-mcp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "opencloud-mcp";
  };
})
