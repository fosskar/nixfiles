{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "netbird-client";
  version = "0.72.4";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "netbird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YRXXuaqnQBLODcz/FNpIG9Ht+6VGRknE2Q6Q5ZaAIus=";
  };

  vendorHash = "sha256-6FN7l+e75Pw2+v0sktomlck+7daro1i6c4ZV53SRePI=";

  nativeBuildInputs = [ installShellFiles ];

  subPackages = [ "client" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/netbirdio/netbird/version.version=${finalAttrs.version}"
    "-X main.builtBy=nix"
  ];

  # make it compatible with systemd's RuntimeDirectory
  postPatch = ''
    substituteInPlace client/cmd/root.go \
      --replace-fail 'unix:///var/run/netbird.sock' 'unix:///var/run/netbird/sock'
    substituteInPlace client/ui/client_ui.go \
      --replace-fail 'unix:///var/run/netbird.sock' 'unix:///var/run/netbird/sock'
  '';

  doCheck = false;

  postInstall = ''
    mv $out/bin/client $out/bin/netbird
    installShellCompletion --cmd netbird \
      --bash <($out/bin/netbird completion bash) \
      --fish <($out/bin/netbird completion fish) \
      --zsh <($out/bin/netbird completion zsh)
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://netbird.io";
    description = "netbird client - connect to the netbird mesh network";
    license = lib.licenses.bsd3;
    mainProgram = "netbird";
  };
})
