{
  fetchFromGitHub,
  buildNpmPackage,
  nodejs_22,
  python3,
  prisma-engines_6,
  makeWrapper,
  nix-update-script,
}:
buildNpmPackage (finalAttrs: {
  pname = "sprout-track";
  version = "1.6.6";
  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "Oak-and-Sprout";
    repo = "sprout-track";
    rev = finalAttrs.version;
    hash = "sha256-m21WcShYO9e1Bzt3NiKWAdc7dxlEnkAZSE52W1Oh9sQ=";
  };

  npmDepsHash = "sha256-DOZ27E8K2YcDGeblP2y93Si/D0C7X8+Gwg7Ue3qOhJ8=";

  # upstream ships no next.config; inject ours (webpack + skip type-check)
  postPatch = ''
    cp ${./next.config.mjs} next.config.mjs
  '';

  # prisma-engines_6's setup-hook exports PRISMA_*_BINARY so `prisma
  # generate` uses the local engines instead of downloading them. python3
  # is needed for better-sqlite3's node-gyp install script.
  nativeBuildInputs = [
    prisma-engines_6
    python3
    makeWrapper
  ];

  env = {
    DATABASE_PROVIDER = "sqlite";
    DATABASE_URL = "file:../db/baby-tracker.db";
    LOG_DATABASE_URL = "file:../db/api-logs.db";
    NEXT_TELEMETRY_DISABLED = "1";
    # next/font/google fetches fonts at build time; no network in the sandbox
    NEXT_FONT_GOOGLE_MOCKED_RESPONSES = "${./mocked-google-fonts.js}";
  };

  buildPhase = ''
    runHook preBuild
    npm run prisma:generate
    npm run prisma:generate:log
    # Turbopack (next 16 default) can't resolve its internal font module
    # under NEXT_FONT_GOOGLE_MOCKED_RESPONSES; webpack's font loader can.
    npm run build -- --webpack
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    appDir="$out/libexec/sprout-track"
    mkdir -p "$appDir" "$out/bin"
    cp -r . "$appDir/"
    chmod -R u+w "$appDir"

    # writable-at-runtime dirs; the nix store is read-only. prisma's sqlite
    # schema resolves file:../db/... relative to the schema, the app resolves
    # Files/ relative to cwd, and Next.js writes its image cache below .next.
    ln -sfn /var/lib/sprout-track/db "$appDir/db"
    ln -sfn /var/lib/sprout-track/Files "$appDir/Files"
    rm -rf "$appDir/.next/cache"
    ln -s /var/cache/sprout-track "$appDir/.next/cache"

    makeWrapper ${nodejs_22}/bin/node "$out/bin/sprout-track" \
      --chdir "$appDir" \
      --prefix PATH : "$appDir/node_modules/.bin" \
      --set PRISMA_QUERY_ENGINE_LIBRARY ${prisma-engines_6}/lib/libquery_engine.node \
      --add-flags "$appDir/node_modules/next/dist/bin/next start"

    makeWrapper ${nodejs_22}/bin/node "$out/bin/sprout-track-prisma" \
      --chdir "$appDir" \
      --prefix PATH : "$appDir/node_modules/.bin" \
      --set PRISMA_SCHEMA_ENGINE_BINARY ${prisma-engines_6}/bin/schema-engine \
      --set PRISMA_QUERY_ENGINE_BINARY ${prisma-engines_6}/bin/query-engine \
      --set PRISMA_QUERY_ENGINE_LIBRARY ${prisma-engines_6}/lib/libquery_engine.node \
      --set PRISMA_FMT_BINARY ${prisma-engines_6}/bin/prisma-fmt \
      --add-flags "$appDir/node_modules/prisma/build/index.js"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Self-hosted baby activity and milestone tracker";
    homepage = "https://github.com/Oak-and-Sprout/sprout-track";
    changelog = "https://github.com/Oak-and-Sprout/sprout-track/releases/tag/${finalAttrs.version}";
    license = {
      fullName = "Sprout Track License (attribution + share-alike)";
      url = "https://github.com/Oak-and-Sprout/sprout-track/blob/main/LICENSE.md";
    };
    mainProgram = "sprout-track";
  };
})
