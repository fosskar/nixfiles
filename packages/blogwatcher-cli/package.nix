{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "blogwatcher-cli";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "JulienTant";
    repo = "blogwatcher-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-A4YoTPKTMVCG2t77wiUooNYGIY4VS7Sx6na/D2KKGu8=";
  };

  vendorHash = "sha256-fWHRGM83VbBwh3W9+PrNwxNwX2w/1sOe+c4z+yLI5cE=";

  subPackages = [ "cmd/blogwatcher-cli" ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Monitor blogs and RSS or Atom feeds";
    homepage = "https://github.com/JulienTant/blogwatcher-cli";
    changelog = "https://github.com/JulienTant/blogwatcher-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "blogwatcher-cli";
  };
})
