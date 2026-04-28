{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:
buildGoModule rec {
  pname = "newt";
  version = "1.12.0";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "newt";
    tag = version;
    hash = "sha256-csD7QcSQE4/eRw3EHX0m2nI3JjglFxXlnyuS4xpCmRY=";
  };

  vendorHash = "sha256-+zMSzNbqmWm/DXL2xMUd5uPP5tSIybsRokwJ2zd0pf0=";

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
