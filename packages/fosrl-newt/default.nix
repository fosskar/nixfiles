{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:
buildGoModule rec {
  pname = "newt";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "newt";
    tag = version;
    hash = "sha256-CHrBMHjRvxE78FfooYAH7NOUKNPxbHnWLMkJ4kH3Qkc=";
  };

  vendorHash = "sha256-YIcuj1S+ZWAzXZOMZbppTvsDcW1W1Sy8ynfMkzLMQpM=";

  nativeInstallCheckInputs = [ versionCheckHook ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.newtVersion=${version}"
  ];

  doInstallCheck = true;

  versionCheckProgramArg = [ "-version" ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--use-github-releases"
      "--version-regex"
      ''v?(\d+\.\d+\.\d+)$''
    ];
  };

  meta = {
    description = "Tunneling client for Pangolin";
    homepage = "https://github.com/fosrl/newt";
    changelog = "https://github.com/fosrl/newt/releases/tag/${src.tag}";
    license = lib.licenses.agpl3Only;
    # upstream nixpkgs maintainers: fab, jackr, sigmasquadron, water-sucks
    maintainers = [ ];
    mainProgram = "newt";
  };
}
