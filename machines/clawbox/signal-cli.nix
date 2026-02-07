{ pkgs, ... }:
let
  signalAccount = "+4915251840217";
  signalHttpListen = "127.0.0.1:8080";
in
{
  systemd.services.signal-cli-daemon = {
    description = "signal-cli daemon (external mode for OpenClaw)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.signal-cli}/bin/signal-cli -a ${signalAccount} daemon --http ${signalHttpListen}";
      Restart = "always";
      RestartSec = "5s";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      ReadWritePaths = [ "/root/.local/share/signal-cli" ];
    };
  };
}
