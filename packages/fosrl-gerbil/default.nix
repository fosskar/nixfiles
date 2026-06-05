{
  lib,
  iptables,
  fetchFromGitHub,
  buildGoModule,
  nix-update-script,
}:
buildGoModule rec {
  pname = "gerbil";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "gerbil";
    tag = version;
    hash = "sha256-wKqJfiCzmMbKZXJGB7BWoXRNDukc4t+PX60XyynJNAU=";
  };

  vendorHash = "sha256-S5olgsmX0uZR9P/u/8Rf3lzRCSIwPDcmlvSzJhhJM3w=";

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
