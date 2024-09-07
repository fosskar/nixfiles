{ pkgs, lib, ... }:
{
  # Avoid the Linux kernel locking itself when we're putting too much
  # strain on the memory. This helps avoid having to shut down
  # forcefully when we OOM
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    reportInterval = 0;
    freeSwapThreshold = 2;
    freeMemThreshold = 4;
    extraArgs =
      let
        # i care about those applications
        appsToAvoid = lib.concatStringsSep "|" [
          "Hyprland" # avoid killing the graphical session
          "wezterm" # terminal, might have unsaved files
          "dbus-.*" # avoid killing the dbus daemon & the dbus broker
          "Xwayland" # avoid killing the X11 server
          "gpg-agent" # avoid killing the gpg agent
          "systemd" # avoid killing systemd
          "systemd-.*" # avoid killing systemd microservices
          "ssh-agent" # avoid killing the ssh agent
        ];

        # dont care about those apps please delete electrom from the internet
        appsToPrefer = lib.concatStringsSep "|" [
          "Web Content"
          "Isolated Web Co"
          "chromium.*"
          "electron"
          ".*.exe"
        ];
      in
      [
        "-g" # kill all processes within a process group
        "--avoid '^(${appsToAvoid})$'" # things we want to not kill
        "--prefer '^(${appsToPrefer})$'" # things we want to kill as soon as possible
      ];

    # we should ideally write the logs into a designated log file; or even better, to the journal
    # for now we can hope this echo sends the log to somewhere we can observe later
    killHook = pkgs.writeShellScript "earlyoom-kill-hook" ''
      echo "Process $EARLYOOM_NAME ($EARLYOOM_PID) was killed"
    '';
  };

  # Harden the earlyoom service based on some upstream defaults
  # and some other options that I prefer having set. Normally
  # I look at a stable distro, such as Fedora, before setting
  # serviceConfig options but as far as I can tell, Fedora does
  # not provide a serviceConfig for earlyOOM.
  systemd.services.earlyoom.serviceConfig = {
    # from upstream
    DynamicUser = true;
    AmbientCapabilities = "CAP_KILL CAP_IPC_LOCK";
    Nice = -20;
    OOMScoreAdjust = -100;
    ProtectSystem = "strict";
    ProtectHome = true;
    Restart = "always";
    TasksMax = 10;
    MemoryMax = "50M";

    # Protection rules. Mostly from the `systemd-oomd` service
    # with some of them already included upstream.
    CapabilityBoundingSet = "CAP_KILL CAP_IPC_LOCK";
    PrivateDevices = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;

    PrivateNetwork = true;
    IPAddressDeny = "any";
    RestrictAddressFamilies = "AF_UNIX";

    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@resources @privileged"
    ];
  };
}
