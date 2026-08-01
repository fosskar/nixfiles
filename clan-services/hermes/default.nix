{ self }:
_: {
  _class = "clan.service";

  manifest.name = "hermes";
  manifest.description = "Hermes agent server and remote desktop clients";
  manifest.readme = builtins.readFile ./README.md;
  manifest.categories = [ "AI" ];

  roles.server = {
    description = "Host the Hermes agent VM and its loopback dashboard forward";
    perInstance = _: {
      nixosModule = {
        imports = [ self.modules.nixos.hermesAgentServer ];
      };
    };
  };

  roles.client = {
    description = "Connect Hermes Desktop to the server over SSH";
    perInstance =
      {
        meta,
        roles,
        ...
      }:
      {
        nixosModule =
          { lib, ... }:
          let
            serverNames = lib.naturalSort (lib.attrNames (roles.server.machines or { }));
            server = if lib.length serverNames == 1 then lib.head serverNames else null;
          in
          {
            imports = [ self.modules.nixos.hermesRemote ];

            services.hermes-remote = lib.mkIf (server != null) {
              enable = true;
              host = "${server}.${meta.domain}";
            };

            assertions = [
              {
                assertion = lib.length serverNames == 1;
                message = "clan hermes client requires exactly one machine with the server role";
              }
            ];
          };
      };
  };
}
