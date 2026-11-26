{
  flake.modules.nixos.tangledKnot =
    {
      flake-self,
      inputs,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "knot";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      listenPort = 5555;
    in
    {
      imports = [ inputs.tangled.nixosModules.knot-rs ];

      config = {
        # losing this key makes the knot's sealed signing key, and with it
        # every repo DID it hosts, unrecoverable
        clan.core.vars.generators.tangled-knot = {
          files.env = { };
          runtimeInputs = [ pkgs.openssl ];
          script = ''
            printf 'KNOT_MASTER_KEY=%s\n' "$(openssl rand -base64 32)" > "$out/env"
          '';
        };

        services.tangled.knot-rs = {
          enable = true;
          environmentFile = config.clan.core.vars.generators.tangled-knot.files.env.path;
          openFirewall = false;
          settings = {
            server = {
              hostname = publicHost;
              admins = [ "did:plc:an4f4yxu6sfuhvc7ih56dyl2" ];
              listen_addr = "0.0.0.0:${toString listenPort}";
            };
            # nix cannot open sha256 repositories, so nixbot could not build them
            git.object_format = "sha1";
            atproto.plc_directory = "https://plc.directory";
            contact.email = "admin@${flake-self.domains.public}";
          };
        };

        services.gatus.settings.endpoints = [
          {
            name = "Tangled Knot";
            url = "https://${publicHost}/xrpc/_health";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
    };
}
