{ pkgs, ... }:
let
  signalAccount = "+4915251840217";
  signalHttpListen = "127.0.0.1:8080";
  jvmArgs = [
    "-Xms64m"
    "-Xmx128m"
    "-XX:+UseSerialGC"
    "-XX:MaxMetaspaceSize=64m"
  ];
in
{
  # ensure openclaw starts after signal-cli is up
  systemd.services.openclaw.after = [ "signal-cli-daemon.service" ];

  systemd.services.signal-cli-daemon = {
    description = "signal-cli daemon (external mode for OpenClaw)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment.JAVA_TOOL_OPTIONS = builtins.concatStringsSep " " jvmArgs;

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.signal-cli}/bin/signal-cli -a ${signalAccount} daemon --http ${signalHttpListen} --ignore-stories --send-read-receipts";
      Restart = "always";
      RestartSec = "5s";
      MemoryMax = "512M";

      # hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      ReadWritePaths = [ "/root/.local/share/signal-cli" ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
    };
  };
}
