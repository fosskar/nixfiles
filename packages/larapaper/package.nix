{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchNpmDeps,
  buildPackages,
  nodejs,
  php84,
  dataDir ? "/var/lib/larapaper",
}:
let
  php = php84.buildEnv {
    extensions = { enabled, all }: enabled ++ [ all.imagick ];
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "larapaper";
  version = "0.44.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "usetrmnl";
    repo = "larapaper";
    tag = finalAttrs.version;
    hash = "sha256-JNn9UV4y84DeUp747OEKLCLlaGy9epSjm5vrf4AxzkY=";
  };

  # a failing plugin in a mashup gets an error tile instead of blanking the screen; not upstream
  patches = [ ./mashup-plugin-errors.patch ];

  buildInputs = [ php ];

  nativeBuildInputs = [
    nodejs
    buildPackages.npmHooks.npmConfigHook
    php.packages.composer
    php.composerHooks2.composerInstallHook
  ];

  composerVendor = php.mkComposerVendor {
    inherit (finalAttrs) pname src version;
    composerNoDev = true;
    composerStrictValidation = false;
    strictDeps = true;
    vendorHash = "sha256-2ReTl2Bpp/hk77KdtqEDXye0DeyeATb5devjGiNWC/0=";
  };

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    hash = "sha256-nYaZoWuzqO9MLaxcPEHH2kpQ39sOM94SsscK/Jm8VmU=";
  };

  env.PUPPETEER_SKIP_DOWNLOAD = "1";

  preInstall = ''
    npm run build
  '';

  postInstall = ''
    chmod -R u+w $out/share
    mv $out/share/php/larapaper/* $out/
    rm -R $out/share $out/storage $out/bootstrap/cache
    ln -s ${dataDir}/storage $out/storage
    ln -s ${dataDir}/cache $out/bootstrap/cache
    ln -s ${dataDir}/storage/app/public $out/public/storage
  '';

  passthru.phpPackage = php;

  meta = {
    description = "Self-hosted TRMNL server (BYOS) in Laravel";
    homepage = "https://github.com/usetrmnl/larapaper";
    changelog = "https://github.com/usetrmnl/larapaper/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
