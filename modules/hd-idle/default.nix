{ lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.hdparm ];

  systemd.services.hd-idle = {
    description = "hd-idle - spin down idle hard disks";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.hd-idle} -i 600 -c ata"; # logs to journald
      Restart = "always";

      # sandboxing
      PrivateTmp = true;
      WorkingDirectory = "/tmp";
      DynamicUser = true;
      User = "hd-idle";
      Group = "hd-idle";

      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      NoNewPrivileges = true;
      MemoryDenyWriteExecute = true;
      DevicePolicy = "closed";
      LockPersonality = true;
      PrivateDevices = false;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [ ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SupplementaryGroups = [ "disk" ];
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
      UMask = "0077";

      # disk access
      AmbientCapabilities = [
        "CAP_SYS_RAWIO"
        "CAP_SYS_ADMIN"
      ];
      CapabilityBoundingSet = [
        "CAP_SYS_RAWIO"
        "CAP_SYS_ADMIN"
      ];
      DeviceAllow = [
        "block-blkext rw"
        "block-sd rw"
        "char-nvme rw"
      ];
    };
  };
}
