{
  flake.modules.nixos.suspendThenShutdown =
    { pkgs, ... }:
    {
      systemd.services.suspend-then-shutdown = {
        description = "schedule shutdown after prolonged suspend";
        wantedBy = [ "suspend.target" ];
        before = [ "systemd-suspend.service" ];
        unitConfig.StopWhenUnneeded = true;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # before suspend: set rtc wakeup alarm (12h)
          ExecStart = "${pkgs.util-linux}/bin/rtcwake -m no -s 43200";
          # on resume: if alarm fired (empty/0) -> shutdown; if user woke -> cancel alarm
          ExecStop = pkgs.writeShellScript "suspend-then-shutdown-check" ''
            alarm=$(cat /sys/class/rtc/rtc0/wakealarm 2>/dev/null || echo "set")
            if [ -z "$alarm" ] || [ "$alarm" = "0" ]; then
              ${pkgs.systemd}/bin/systemctl poweroff
            else
              echo 0 > /sys/class/rtc/rtc0/wakealarm
            fi
          '';
        };
      };
    };
}
