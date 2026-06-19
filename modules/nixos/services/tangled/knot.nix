{
  flake.modules.nixos.tangledKnot =
    {
      flake-self,
      inputs,
      ...
    }:
    let
      serviceName = "knot";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      listenPort = 5555;
    in
    {
      imports = [ inputs.tangled.nixosModules.knot ];

      config = {
        services.tangled.knot = {
          enable = true;
          knotmirrors = [ "https://mirror.tangled.network" ];
          server = {
            listenAddr = "0.0.0.0:${toString listenPort}";
            hostname = publicHost;
            owner = "did:plc:an4f4yxu6sfuhvc7ih56dyl2";
            secureMode = false;
          };
          openFirewall = false;
        };

        services.gatus.settings.endpoints = [
          {
            name = "Tangled Knot";
            url = "https://${publicHost}";
            group = "Automation";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
    };
}
