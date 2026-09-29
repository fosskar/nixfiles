{
  flake.modules.nixos.opencloud =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceConfig = {
        LoadCredential = "envfile:${config.clan.core.vars.generators.opencloud-ocr.files.envfile.path}";
        Nice = 19;
        IOSchedulingClass = "idle";

        DynamicUser = true;
        UMask = "0077";
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        ProtectHome = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        IPAddressAllow = "localhost";
        IPAddressDeny = "any";
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
      };
    in
    {
      clan.core.vars.generators.opencloud-ocr = {
        dependencies = [ "opencloud" ];
        files.envfile.secret = true;
        runtimeInputs = [ pkgs.gnugrep ];
        script = ''
          grep -E '^OC_SERVICE_ACCOUNT_(ID|SECRET)=' $in/opencloud/envfile > $out/envfile
        '';
      };

      systemd.services.opencloud-ocr = {
        description = "ocr scanned pdfs uploaded to opencloud";
        after = [ "opencloud.service" ];
        requires = [ "opencloud.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = serviceConfig // {
          ExecStart = lib.getExe pkgs.local.opencloud-ocr;
          Restart = "on-failure";
          RestartSec = 30;
        };
      };

      # started by hand: systemctl start opencloud-ocr-backfill
      systemd.services.opencloud-ocr-backfill = {
        description = "ocr scanned pdfs already stored in opencloud";
        after = [ "opencloud.service" ];
        requires = [ "opencloud.service" ];
        serviceConfig = serviceConfig // {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.local.opencloud-ocr} backfill";
        };
      };
    };
}
