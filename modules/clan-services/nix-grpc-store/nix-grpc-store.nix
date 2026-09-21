{ self, ... }:
{
  flake.modules."clan.service".nix-grpc-store =
    { lib, ... }:
    let
      port = 50051;
      caGenerator = "nix-grpc-store-ca";
      certGenerator = "nix-grpc-store";

      # one private CA for the whole clan; the key never leaves the vars store
      caVars = pkgs: {
        clan.core.vars.generators.${caGenerator} = {
          share = true;
          files."ca.crt".secret = false;
          files."ca.key" = {
            secret = true;
            deploy = false;
          };
          runtimeInputs = [ pkgs.openssl ];
          script = ''
            openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
              -days 3650 -subj "/CN=nixfiles nix-grpc-store" \
              -keyout "$out/ca.key" -out "$out/ca.crt"
          '';
        };
      };

      # one cert per machine, CN = machine name (the daemon's access rules
      # match on it) and SAN = the name clients dial. serverAuth and
      # clientAuth, so the same cert works in either role
      certVars =
        {
          pkgs,
          machineName,
          domain,
          keyOwner,
        }:
        {
          clan.core.vars.generators.${certGenerator} = {
            dependencies = [ caGenerator ];
            files."cert.pem".secret = false;
            files."key.pem" = {
              secret = true;
              owner = keyOwner;
              group = keyOwner;
            };
            runtimeInputs = [ pkgs.openssl ];
            script = ''
              openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
                -subj "/CN=${machineName}" -keyout "$out/key.pem" -out csr.pem
              printf 'subjectAltName=DNS:%s,DNS:%s\nextendedKeyUsage=serverAuth,clientAuth\n' \
                "${machineName}.${domain}" "${machineName}" > ext.cnf
              openssl x509 -req -in csr.pem -days 3650 \
                -CA "$in/${caGenerator}/ca.crt" -CAkey "$in/${caGenerator}/ca.key" \
                -set_serial "0x$(openssl rand -hex 16)" -extfile ext.cnf \
                -out "$out/cert.pem"
            '';
          };
        };
    in
    {
      manifest.name = "nix-grpc-store";
      manifest.description = "nix remote builds over grpc with mtls";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "Developer Tools" ];

      roles.builder = {
        description = "machine running nix-grpc-daemon for the clan's builds";

        interface =
          { lib, ... }:
          {
            options = {
              maxJobs = lib.mkOption {
                type = lib.types.ints.positive;
                default = 8;
                description = "parallel builds advertised to clients";
              };
              systems = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "x86_64-linux" ];
                description = "systems advertised to clients";
              };
              speedFactor = lib.mkOption {
                type = lib.types.ints.positive;
                default = 10;
                description = "relative builder speed advertised to clients";
              };
              supportedFeatures = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "nixos-test"
                  "big-parallel"
                  "kvm"
                  "uid-range"
                  "recursive-nix"
                ];
                description = "features advertised to clients; uid-range and recursive-nix also enable the matching nix settings on the builder";
              };
            };
          };

        perInstance =
          { roles, settings, ... }:
          {
            nixosModule =
              {
                config,
                lib,
                pkgs,
                ...
              }:
              let
                builderMachines = roles.builder.machines or { };
                clientMachines = lib.filter (m: !(builderMachines ? ${m})) (
                  lib.attrNames (roles.client.machines or { })
                );
                vars = config.clan.core.vars.generators;
              in
              {
                imports = [
                  self.inputs.nix-grpc-store.nixosModules.server
                  (caVars pkgs)
                  (certVars {
                    inherit pkgs;
                    machineName = config.clan.core.settings.machine.name;
                    domain = config.clan.core.settings.domain;
                    keyOwner = "nix-grpc-daemon";
                  })
                ];

                services.nix-grpc-daemon = {
                  enable = true;
                  listen = "0.0.0.0:${toString port}";
                  tls = {
                    certFile = vars.${certGenerator}.files."cert.pem".path;
                    keyFile = vars.${certGenerator}.files."key.pem".path;
                    clientCaFile = vars.${caGenerator}.files."ca.crt".path;
                  };
                  # nix.buildMachines uploads unsigned client-built inputs,
                  # which only a trusted user may do; the access rules limit
                  # that to the clan's client certificates
                  trustClients = true;
                  accessRules = map (machine: {
                    cn = machine;
                    role = "trusted";
                  }) clientMachines;
                };

                networking.firewall.allowedTCPPorts = [ port ];

                nix.settings = {
                  max-jobs = lib.mkDefault settings.maxJobs;
                  cores = lib.mkDefault 0;
                  experimental-features = lib.mkAfter (
                    [
                      "auto-allocate-uids"
                      "cgroups"
                    ]
                    ++ lib.optional (lib.elem "recursive-nix" settings.supportedFeatures) "recursive-nix"
                  );
                  auto-allocate-uids = lib.mkDefault true;
                  # nixbot builds untrusted pull requests here; contain every
                  # build in a cgroup so its process tree dies atomically
                  use-cgroups = lib.mkDefault true;
                  system-features = lib.mkAfter (
                    lib.intersectLists [
                      "uid-range"
                      "recursive-nix"
                    ] settings.supportedFeatures
                  );
                };

                security.pam.loginLimits = [
                  {
                    domain = "nix-grpc-daemon";
                    item = "nofile";
                    type = "-";
                    value = "20480";
                  }
                ];
              };
          };
      };

      roles.client = {
        description = "machine offloading nix builds to the grpc builder";

        perInstance =
          { roles, machine, ... }:
          {
            nixosModule =
              {
                config,
                lib,
                pkgs,
                ...
              }:
              let
                builderMachines = roles.builder.machines or { };
                isBuilder = builderMachines ? ${machine.name};
                vars = config.clan.core.vars.generators;
                # the plugin looks for client.crt/client.key here by default
                certDir = "/run/nix-grpc-store";
              in
              {
                imports = [
                  self.inputs.nix-grpc-store.nixosModules.client
                ]
                ++ lib.optionals (!isBuilder) [
                  (caVars pkgs)
                  (certVars {
                    inherit pkgs;
                    machineName = machine.name;
                    domain = config.clan.core.settings.domain;
                    keyOwner = "root";
                  })
                ];

                config = lib.mkIf (!isBuilder) {
                  programs.nix-grpc-store.enable = true;
                  nix.distributedBuilds = lib.mkDefault true;

                  systemd.tmpfiles.rules = [
                    "d ${certDir} 0700 root root -"
                    "L+ ${certDir}/client.crt - - - - ${vars.${certGenerator}.files."cert.pem".path}"
                    "L+ ${certDir}/client.key - - - - ${vars.${certGenerator}.files."key.pem".path}"
                  ];

                  nix.buildMachines = lib.mapAttrsToList (
                    builderName: builder:
                    let
                      inherit (builder) settings;
                    in
                    {
                      hostName = "grpc://${builderName}.${config.clan.core.settings.domain}:${toString port}?ca-cert=${
                        vars.${caGenerator}.files."ca.crt".path
                      }";
                      protocol = null;
                      inherit (settings)
                        systems
                        maxJobs
                        speedFactor
                        supportedFeatures
                        ;
                    }
                  ) builderMachines;
                };
              };
          };
      };
    };
}
