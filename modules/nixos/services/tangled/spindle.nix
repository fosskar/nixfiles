{
  flake.modules.nixos.tangledSpindle =
    {
      flake-self,
      inputs,
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
        boot.kernelModules = [ "vhost_vsock" ];

        services.tangled.spindle = {
          enable = true;
          server = {
            listenAddr = "0.0.0.0:${toString listenPort}";
            hostname = publicHost;
            owner = "did:plc:an4f4yxu6sfuhvc7ih56dyl2";
          };
        };

        services.gatus.settings.endpoints = [
          {
            name = "Tangled Spindle";
            url = "https://${publicHost}";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
    };
}
