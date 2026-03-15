{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:

buildGoModule (finalAttrs: {
  pname = "netbird-client";
  version = "0.66.4";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "netbird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-orHi9dqdYhYaU0hrnHWuE9IHrqbWRsfuXZitmRmJXeA=";
  };

  vendorHash = "sha256-vyf3zLTMtkmt+AXfCTRSPZ/TaJ8VP/5IzNbJwxQcfPs=";

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

  meta = {
    homepage = "https://netbird.io";
    description = "netbird client - connect to the netbird mesh network";
    license = lib.licenses.bsd3;
    mainProgram = "netbird";
  };
})
