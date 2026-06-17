{
  flake.modules.nixos.tangledSpindle =
    {
      flake-self,
      inputs,
      nflib,
      ...
    }:
    let
      serviceName = "spindle";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      listenPort = 6555;
    in
    {
      imports = [ inputs.tangled.nixosModules.spindle ];

      config = {
        services.tangled.spindle = {
          enable = true;
          server = {
            listenAddr = "0.0.0.0:${toString listenPort}";
            hostname = publicHost;
            owner = "did:plc:an4f4yxu6sfuhvc7ih56dyl2";
          };
        };

        services.homepage-dashboard.serviceGroups."code" = [
          {
            "Tangled Spindle" = {
              href = "https://${publicHost}";
              icon = "mdi-cog";
              siteMonitor = "https://${publicHost}";
            };
          }
        ];

        services.gatus.settings.endpoints = [
          (nflib.gatusEndpoint {
            name = "Tangled Spindle";
            url = "https://${publicHost}";
            group = "Automation";
          })
        ];
      };
    };
}
