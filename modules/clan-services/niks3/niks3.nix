{ self, ... }:
{
  flake.modules."clan.service".niks3 =
    { lib, ... }:
    let
      inherit (lib) attrNames flip;

      # shared sign-key generator (server signs, clients trust pubkey).
      varsForInstance = instanceName: pkgs: {
        clan.core.vars.generators."niks3" = {
          share = true;
          files.sign-key.secret = true;
          files.sign-key.deploy = false;
          files.pub-key.secret = false;
          script = ''
            ${pkgs.nix}/bin/nix-store --generate-binary-cache-key ${instanceName}-1 \
              $out/sign-key \
              $out/pub-key
          '';
        };
      };
    in
    {
      manifest.name = "niks3";
      manifest.description = "self-hosted nix binary cache via niks3 with bundled garage s3 backend";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "Nix Tools" ];

      roles.server = {
        description = "niks3 server with bundled garage s3 backend";

        perInstance =
          { instanceName, ... }:
          {
            nixosModule =
              {
                config,
                pkgs,
                lib,
                ...
              }:
              let
                niks3Pkgs = self.inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system};
                # cache bucket owned by the garage clan-service: declared in the
                # garage instance's `buckets`, key pre-generated in `garage-buckets`.
                bucketName = "niks3-cache";
                niks3Port = 5751;
                garageS3Port = 3900;
                garageWebPort = 3902;
                varsGarage = config.clan.core.vars.generators."niks3-garage";
                varsKeys = config.clan.core.vars.generators."niks3-private";
              in
              {
                imports = [
                  (varsForInstance instanceName pkgs)
                  self.inputs.niks3.nixosModules.niks3
                  self.inputs.niks3.nixosModules.niks3-auto-upload
                ];

                # private copy of sign-key (deployed to host, used by niks3 server).
                clan.core.vars.generators."niks3-private" = {
                  dependencies = [ "niks3" ];
                  files.sign-key.secret = true;
                  files.sign-key.owner = "niks3";
                  files.sign-key.group = "niks3";
                  script = "cp $in/niks3/sign-key $out/sign-key";
                };

                clan.core.vars.generators."niks3-garage" = {
                  files.api-token.secret = true;
                  files.api-token.owner = "niks3";
                  files.api-token.group = "niks3";
                  runtimeInputs = [ pkgs.openssl ];
                  script = ''
                    openssl rand -hex 32 > "$out/api-token"
                  '';
                };

                # private copy of the cache bucket key, owned by niks3 (the shared
                # garage-buckets originals are root-owned).
                clan.core.vars.generators."niks3-s3" = {
                  dependencies = [ "garage-buckets" ];
                  files.access-key.owner = "niks3";
                  files.access-key.group = "niks3";
                  files.secret-key.owner = "niks3";
                  files.secret-key.group = "niks3";
                  script = ''
                    cp $in/garage-buckets/niks3-cache_access_key_id $out/access-key
                    cp $in/garage-buckets/niks3-cache_secret_access_key $out/secret-key
                  '';
                };

                # ----- niks3 server -----
                services.niks3 = {
                  enable = true;
                  httpAddr = "0.0.0.0:${toString niks3Port}";

                  database.createLocally = false;
                  database.connectionString = "postgres:///niks3?host=/run/postgresql";

                  s3 = {
                    endpoint = "127.0.0.1:${toString garageS3Port}";
                    bucket = bucketName;
                    region = config.networking.hostName;
                    useSSL = false;
                    accessKeyFile = config.clan.core.vars.generators."niks3-s3".files.access-key.path;
                    secretKeyFile = config.clan.core.vars.generators."niks3-s3".files.secret-key.path;
                  };

                  apiTokenFile = varsGarage.files.api-token.path;
                  signKeyFiles = [ varsKeys.files.sign-key.path ];

                  readProxy.enable = true;

                  gc.enable = true;
                  gc.olderThan = "720h";
                };

                # bucket + key are provisioned by garage-buckets-init on the garage
                # bootstrap node; locally only the daemon order matters.
                systemd.services.niks3.after = [
                  "garage.service"
                  "postgresql.service"
                ];

                # postgres via clan-core wrapper (consistent with paperless/immich/etc).
                clan.core.postgresql.enable = true;
                clan.core.postgresql.databases.niks3 = {
                  create.enable = true;
                  create.options.OWNER = "niks3";
                  restore.stopOnRestore = [ "niks3.service" ];
                };
                clan.core.postgresql.users.niks3 = { };

                # ----- system-wide post-build-hook upload -----
                services.niks3-auto-upload = {
                  enable = true;
                  package = niks3Pkgs.niks3-hook;
                  serverUrl = "http://127.0.0.1:${toString niks3Port}";
                  authTokenFile = varsGarage.files.api-token.path;
                };

                # ----- nixbot niks3 upload -----
                # disabled: nix post-build-hook already uploads local nixbot builds.
                services.nixbot.niks3 = lib.mkIf config.services.nixbot.enable {
                  enable = false;
                  serverUrl = "http://127.0.0.1:${toString niks3Port}";
                  authTokenFile = varsGarage.files.api-token.path;
                  package = niks3Pkgs.niks3;
                };

                # firewall: niks3 server + garage web endpoint (anonymous reads).
                networking.firewall.allowedTCPPorts = [
                  niks3Port
                  garageWebPort
                ];
              };
          };
      };

      roles.client = {
        description = "machine using niks3 cache as substituter";

        perInstance =
          {
            instanceName,
            roles,
            ...
          }:
          {
            nixosModule =
              {
                config,
                pkgs,
                lib,
                ...
              }:
              {
                imports = [ (varsForInstance instanceName pkgs) ];

                nix.settings = lib.mkIf (!(builtins.hasAttr config.networking.hostName roles.server.machines)) {
                  substituters =
                    let
                      inherit (config.clan.core.settings) domain;
                      dotDomain = if domain != null then ".${domain}" else "";
                    in
                    flip map (attrNames roles.server.machines) (
                      machineName: "http://${machineName}${dotDomain}:3902?priority=1"
                    );

                  trusted-public-keys = [
                    config.clan.core.vars.generators."niks3".files.pub-key.value
                  ];
                };
              };
          };
      };
    };
}
