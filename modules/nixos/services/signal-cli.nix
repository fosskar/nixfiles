{
  flake.modules.nixos.signalCli =
    { pkgs, ... }:
    let
      signalHttpListen = "127.0.0.1:18081";
      stateDir = "/var/lib/signal-cli";
      # sizing comes from the cgroup (MemoryMax); a hard MaxMetaspaceSize
      # killed the receive thread with ClassNotFoundException on lazy class
      # loads (attachment downloads) while systemd still saw a running unit.
      # ExitOnOutOfMemoryError turns in-JVM OOM into an exit so Restart heals.
      jvmArgs = [
        "-XX:MaxRAMPercentage=50"
        "-XX:+ExitOnOutOfMemoryError"
      ];
    in
    {
      environment.systemPackages = [ pkgs.small.signal-cli ];

      users.groups.signal-cli = { };
      users.users.signal-cli = {
        isSystemUser = true;
        group = "signal-cli";
        home = stateDir;
      };

      systemd.services.signal-cli-daemon = {
        description = "signal-cli HTTP daemon";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        environment = {
          HOME = stateDir;
          JAVA_TOOL_OPTIONS = builtins.concatStringsSep " " jvmArgs;
        };

        serviceConfig = {
          Type = "simple";
          User = "signal-cli";
          Group = "signal-cli";
          ExecStart = "${pkgs.small.signal-cli}/bin/signal-cli --data-dir ${stateDir} --scrub-log daemon --http ${signalHttpListen} --no-receive-stdout --ignore-stories";
          Restart = "always";
          RestartSec = "5s";
          MemoryMax = "512M";
          StateDirectory = "signal-cli";
          StateDirectoryMode = "0700";
          UMask = "0077";

          CapabilityBoundingSet = "";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
        };
      };
    };
}
