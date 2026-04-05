{
  lib,
  iptables,
  fetchFromGitHub,
  buildGoModule,
  nix-update-script,
}:
buildGoModule rec {
  pname = "gerbil";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "gerbil";
    tag = version;
    hash = "sha256-Y5ihrcRAPerpdp/ybjaztUs3ZmssB9jIBmUC1TLSUc8=";
  };

  vendorHash = "sha256-FZuIDHAQtqEuxE1W4yYRnr4Kj8YedNi0Z1NeuWrgnRc=";

  # patch out the /usr/sbin/iptables
  postPatch = ''
    substituteInPlace main.go \
      --replace-fail '/usr/sbin/iptables' '${lib.getExe iptables}'
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--use-github-releases" ];
  };

  meta = {
    description = "Simple WireGuard interface management server";
    mainProgram = "gerbil";
    homepage = "https://github.com/fosrl/gerbil";
    changelog = "https://github.com/fosrl/gerbil/releases/tag/${version}";
    license = lib.licenses.agpl3Only;
    # upstream: jackr, sigmasquadron
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
}
