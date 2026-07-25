{
  flake.modules.nixos.signalCli =
    { pkgs, ... }:
    let
      signalAccount = "+4915251840217";
      signalHttpListen = "127.0.0.1:18081";
      stateDir = "/root/.local/share/signal-cli";
      jvmArgs = [
        "-Xms64m"
        "-Xmx128m"
        "-XX:+UseSerialGC"
        "-XX:MaxMetaspaceSize=64m"
      ];
    in
    {
      systemd.tmpfiles.rules = [ "d ${stateDir} 0700 root root -" ];

      systemd.services.signal-cli-daemon = {
        description = "signal-cli daemon (external mode for OpenClaw)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        environment.JAVA_TOOL_OPTIONS = builtins.concatStringsSep " " jvmArgs;

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.small.signal-cli}/bin/signal-cli -a ${signalAccount} daemon --http ${signalHttpListen} --no-receive-stdout --ignore-stories --send-read-receipts";
          Restart = "always";
          RestartSec = "5s";
          MemoryMax = "512M";

          # hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = false;
          ReadWritePaths = [ stateDir ];
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
        };
      };
    };
}
