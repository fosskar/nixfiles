{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

buildGoModule rec {
  pname = "newt";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "newt";
    tag = version;
    hash = "sha256-pGanh8shR1WE4AfjVzAVSZ8Xj5gKegFVmRRbYfEtU68=";
  };

  vendorHash = "sha256-Sib6AUCpMgxlMpTc2Esvs+UU0yduVOxWUgT44FHAI+k=";

  nativeInstallCheckInputs = [ versionCheckHook ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.newtVersion=${version}"
  ];

  doInstallCheck = true;

  versionCheckProgramArg = [ "-version" ];

  passthru.updateScript = nix-update-script { };

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
