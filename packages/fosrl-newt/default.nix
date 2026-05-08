{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:
buildGoModule rec {
  pname = "newt";
  version = "1.12.4";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "newt";
    tag = version;
    hash = "sha256-wYLnuKIU+wcCxF57cdfepTVm52btfdrveQ8Y+R9flMo=";
  };

  vendorHash = "sha256-WfIK+Q8WQ372NzLw6DRapv1nYPduShi4KnVJBPk0Oz0=";

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
