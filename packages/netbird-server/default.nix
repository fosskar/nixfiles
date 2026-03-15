{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "netbird-server";
  version = "0.66.4";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "netbird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-orHi9dqdYhYaU0hrnHWuE9IHrqbWRsfuXZitmRmJXeA=";
  };

  vendorHash = "sha256-vyf3zLTMtkmt+AXfCTRSPZ/TaJ8VP/5IzNbJwxQcfPs=";

  subPackages = [ "combined" ];

  postPatch = ''
    substituteInPlace combined/cmd/config.go \
      --replace-fail \
      $'// Build HTTP config (required, even if empty)\n\thttpConfig := &nbconfig.HttpServerConfig{}\n' \
      $'// Build HTTP config (required, even if empty)\n\thttpConfig := &nbconfig.HttpServerConfig{}\n\n\t// wire TLS settings from combined server to management listener\n\tif c.Server.TLS.LetsEncrypt.Enabled && len(c.Server.TLS.LetsEncrypt.Domains) > 0 {\n\t\thttpConfig.LetsEncryptDomain = c.Server.TLS.LetsEncrypt.Domains[0]\n\t} else if c.Server.TLS.CertFile != "" && c.Server.TLS.KeyFile != "" {\n\t\thttpConfig.CertFile = c.Server.TLS.CertFile\n\t\thttpConfig.CertKey = c.Server.TLS.KeyFile\n\t}\n'
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/netbirdio/netbird/version.version=${finalAttrs.version}"
    "-X main.builtBy=nix"
  ];

  doCheck = false;

  postInstall = ''
    mv $out/bin/combined $out/bin/netbird-server
  '';

  meta = {
    homepage = "https://netbird.io";
    description = "netbird server (management + signal + relay + stun + embedded IdP)";
    license = lib.licenses.agpl3Only;
    mainProgram = "netbird-server";
  };
})
