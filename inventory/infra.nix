{
  config,
  ...
}:
{
  flake.clan.inventory.instances = {
    garage = {
      module = {
        name = "garage";
        input = "self";
      };
      # cluster-wide; role-level so both nodes agree on the set.
      roles.node.settings.buckets = {
        backup = { };
        # media and durable git data for the buzz relay (inventory/apps.nix);
        # the relay reads it S3-locally on nixbox, no web endpoint.
        buzz-media = { };
        # protomaps basemap for grid; served via the s3 web endpoint and
        # exposed publicly through netbird-proxy (peer target :3902).
        maps = {
          website = true;
          # protomaps-cors sets the bucket cors rules with this key
          owner = true;
          aliases = [
            "maps.${config.flake.domains.public}"
            "maps.${config.flake.domains.local}"
          ];
        };
        # nix binary cache objects for niks3; clients read anonymously via
        # the s3 web endpoint (http://nixworker.s:3902, http://nixworker.lan:3902
        # from the home lan). the public cache maps niks3.<public> here too,
        # so only reads leave the mesh
        niks3-cache = {
          website = true;
          aliases = [
            "nixworker.s"
            "nixworker.lan"
            "niks3.${config.flake.domains.public}"
          ];
        };
      };
      # rpc over the lan: yggdrasil caps the 10g link between the two nodes
      roles.node.machines = {
        "nixbox".settings = {
          capacity = "1T";
          dataPath = "/tank/apps/garage";
          ui.enable = true;
          rpcAddr = config.flake.hosts.nixbox.lan;
        };
        "nixworker".settings = {
          capacity = "1T";
          rpcAddr = config.flake.hosts.nixworker.lan;
        };
      };
    };

    nix-grpc-store = {
      module = {
        name = "nix-grpc-store";
        input = "self";
      };
      roles = {
        # aarch64 through binfmt emulation (boot.binfmt.emulatedSystems on nixworker)
        builder.machines."nixworker".settings.systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        # service no-ops client config on builder machines
        client.tags = [ "all" ];
      };
    };

    harmonia = {
      module = {
        name = "harmonia";
        input = "self";
      };
      roles = {
        server.machines."nixworker" = { };
        client.tags = [ "all" ];
      };
    };

    niks3 = {
      module = {
        name = "niks3";
        input = "self";
      };
      roles = {
        server.machines."nixworker" = { };
        client.tags = [ "all" ];
      };
    };
  };
}
