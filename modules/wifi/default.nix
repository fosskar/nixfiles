{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.wifi;
in
{
  options.nixfiles.wifi = {
    enable = lib.mkEnableOption "iwd wifi with privacy defaults" // {
      default = true;
    };

    credentials = {
      enable = lib.mkEnableOption "manage wifi credentials via clan vars";

      ssid = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "wifi network SSID";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # wireless regulatory database
    hardware.wirelessRegulatoryDatabase = true;

    # persist iwd network profiles
    nixfiles.persistence.directories = [ "/var/lib/iwd" ];

    # iwd + networkmanager wifi settings
    networking = {
      networkmanager.wifi = {
        backend = lib.mkDefault "iwd";
        macAddress = lib.mkDefault "random";
        powersave = lib.mkDefault true;
        scanRandMacAddress = lib.mkDefault true;
      };
      wireless.iwd.settings = {
        Scan.DisablePeriodicScan = true;
        Settings.AutoConnect = true;

        General = {
          AddressRandomization = "network";
          AddressRandomizationRange = "full";
          EnableNetworkConfiguration = true;
          RoamRetryInterval = 15;
        };

        Network = {
          EnableIPv6 = true;
          RoutePriorityOffset = 300;
        };
      };
    };

    # optional: manage wifi credentials via clan vars
    clan.core.vars.generators."wifi-${cfg.credentials.ssid}" =
      lib.mkIf (cfg.credentials.enable && cfg.credentials.ssid != "")
        {
          prompts.password = {
            type = "hidden";
            description = "password for wifi network '${cfg.credentials.ssid}'";
            persist = true;
          };
          files."network.psk" = { };
          script = ''
                      PASSWORD=$(cat $prompts/password)
                      cat > $out/network.psk << EOF
            [Security]
            Passphrase=$PASSWORD
            EOF
          '';
        };

    systemd.services."iwd-deploy-${cfg.credentials.ssid}" =
      lib.mkIf (cfg.credentials.enable && cfg.credentials.ssid != "")
        {
          description = "deploy wifi credentials for ${cfg.credentials.ssid}";
          wantedBy = [ "iwd.service" ];
          before = [ "iwd.service" ];
          after = [ "var-lib-iwd.mount" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            cp ${
              config.clan.core.vars.generators."wifi-${cfg.credentials.ssid}".files."network.psk".path
            } "/var/lib/iwd/${cfg.credentials.ssid}.psk"
            chmod 600 "/var/lib/iwd/${cfg.credentials.ssid}.psk"
          '';
        };
  };
}
