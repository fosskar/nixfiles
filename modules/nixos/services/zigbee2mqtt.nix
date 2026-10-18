{
  flake.modules.nixos.zigbee2mqtt =
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
      cfg = config.services.zigbee2mqtt;
      frontendPort = 8099;
    in
    {
      # zigbee2mqtt resolves "!secret <key>" from secret.yaml in its data dir
      clan.core.vars.generators.zigbee2mqtt = {
        dependencies = [ "mosquitto" ];
        prompts.network-key = {
          description = "zigbee network key, 16 comma-separated numbers (advanced.network_key)";
          persist = true;
        };
        files.network-key = { };
        files."secret.yaml".owner = "zigbee2mqtt";
        runtimeInputs = [
          pkgs.jq
          pkgs.openssl
        ];
        script = ''
          cp "$prompts/network-key" "$out/network-key"
          {
            printf 'network_key: [%s]\n' "$(cat "$prompts/network-key")"
            printf 'password: %s\n' "$(jq -R . < "$in/mosquitto/addons-password")"
            printf 'auth_token: %s\n' "$(openssl rand -hex 32)"
          } > "$out/secret.yaml"
        '';
      };

      services.zigbee2mqtt = {
        enable = true;
        settings = {
          # without it zigbee2mqtt migrates the regenerated file on every start
          version = 5;
          mqtt = {
            user = "addons";
            password = "!secret password";
          };
          serial.adapter = "ember";
          advanced.network_key = "!secret network_key";
          frontend = {
            enabled = true;
            port = frontendPort;
            auth_token = "!secret auth_token";
          };
        };
      };

      systemd.tmpfiles.rules = [
        "L+ ${cfg.dataDir}/secret.yaml - - - - ${
          config.clan.core.vars.generators.zigbee2mqtt.files."secret.yaml".path
        }"
      ];

      networking.firewall.allowedTCPPorts = [ frontendPort ];

      # lan only: the router does not let nixbox (srv) reach this port, so no siteMonitor
      services.homepage-dashboard.services = [
        {
          "admin" = [
            {
              "Zigbee2MQTT" = {
                href = "http://${flake-self.hosts.${config.networking.hostName}.lan}:${toString frontendPort}";
                icon = "zigbee2mqtt.svg";
              };
            }
          ];
        }
      ];
    };
}
