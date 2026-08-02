{ inputs, ... }:
{
  flake.modules.nixos.hermesAgentServer =
    {
      config,
      pkgs,
      ...
    }:
    let
      hybridVsockConnect = pkgs.writers.writeRustBin "hermes-hybrid-vsock-connect" {
        rustcArgs = [
          "-O"
          "--edition"
          "2021"
        ];
      } ./hybrid-vsock-connect.rs;
    in
    {
      clan.core.vars.generators.hermes-dashboard = {
        files.token = {
          owner = "root";
          group = "root";
        };
        runtimeInputs = [ pkgs.openssl ];
        script = ''
          openssl rand -hex 32 > "$out/token"
        '';
      };

      nixfiles.agentVms.hermes.secrets."hermes-dashboard-token" =
        config.clan.core.vars.generators.hermes-dashboard.files.token.path;

      # ssh host alias and root identity come from the agentVm module
      environment.shellAliases.hermes = "ssh -t hermes -- sudo -iu hermes hermes";

      systemd.sockets.hermes-dashboard-forward = {
        description = "Hermes dashboard forward";
        wantedBy = [ "sockets.target" ];
        listenStreams = [ "127.0.0.1:22100" ];
        socketConfig = {
          Accept = true;
          MaxConnections = 64;
        };
      };

      systemd.services."hermes-dashboard-forward@" = {
        description = "Hermes dashboard connection forward";
        after = [ "microvm@hermes.service" ];
        requires = [ "microvm@hermes.service" ];
        serviceConfig = {
          User = "microvm";
          Group = "kvm";
          ExecStart = "${hybridVsockConnect}/bin/hermes-hybrid-vsock-connect /var/lib/microvms/hermes/notify.vsock 9119";
          StandardInput = "socket";
          StandardError = "journal";
          CapabilityBoundingSet = "";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectSystem = "strict";
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          RestrictAddressFamilies = [ "AF_UNIX" ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          UMask = "0077";
        };
      };
    };

  flake.modules.nixos.hermesRemote =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-remote;
      hermesAgent = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
      desktopPackage = pkgs.callPackage ./_desktop.nix {
        inherit (hermesAgent.passthru) hermesNpmLib;
        inherit hermesAgent;
        inherit (pkgs) electron;
      };
      portGuard = import ./_remote-port-guard.nix { inherit pkgs; };
      sshOptions = [
        "-o"
        "ExitOnForwardFailure=yes"
        "-o"
        "BatchMode=yes"
        "-o"
        "ConnectTimeout=10"
        "-o"
        "ControlMaster=no"
        "-o"
        "ControlPath=none"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=3"
      ]
      ++ cfg.extraSshOptions;
      sshOptionsString = lib.escapeShellArgs sshOptions;
      destination = "${cfg.user}@${cfg.host}";
      launcher = pkgs.writeShellScriptBin "hermes-desktop-remote" ''
        set -eu

        started=false
        ${pkgs.systemd}/bin/systemctl --user is-active --quiet hermes-remote-tunnel.service || started=true
        stop_tunnel() {
          if [ "$started" = true ]; then
            ${pkgs.systemd}/bin/systemctl --user stop hermes-remote-tunnel.service || true
          fi
        }

        ${pkgs.systemd}/bin/systemctl --user reset-failed hermes-remote-tunnel.service 2>/dev/null || true
        ${pkgs.systemd}/bin/systemctl --user start hermes-remote-tunnel.service || {
          echo "hermes-desktop-remote: cannot start hermes-remote-tunnel.service" >&2
          exit 1
        }

        ready=false
        squatted=false
        for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
          mainpid="$(${pkgs.systemd}/bin/systemctl --user show \
            --property MainPID --value hermes-remote-tunnel.service || echo 0)"
          guard=0
          ${portGuard}/bin/hermes-remote-port-guard \
            ${toString cfg.localPort} "''${mainpid:-0}" || guard=$?
          if [ "$guard" -eq 0 ]; then
            ready=true
            break
          fi
          if [ "$guard" -eq 2 ]; then
            squatted=true
            break
          fi
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        if [ "$ready" != true ]; then
          stop_tunnel
          if [ "$squatted" = true ]; then
            echo "hermes-desktop-remote: another process owns 127.0.0.1:${toString cfg.localPort}; refusing to send the dashboard token" >&2
          else
            echo "hermes-desktop-remote: SSH tunnel did not become ready" >&2
          fi
          exit 1
        fi

        token="$(${pkgs.openssh}/bin/ssh ${sshOptionsString} ${destination} \
          cat /run/secrets/vars/hermes-dashboard/token || true)"
        if [ -z "$token" ]; then
          stop_tunnel
          echo "hermes-desktop-remote: server returned an empty dashboard token" >&2
          exit 1
        fi

        ready=false
        for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
          if printf 'header = "X-Hermes-Session-Token: %s"\n' "$token" |
            ${pkgs.curl}/bin/curl --config - --fail --silent --output /dev/null \
              "http://127.0.0.1:${toString cfg.localPort}/api/sessions"; then
            ready=true
            break
          fi
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        if [ "$ready" != true ]; then
          stop_tunnel
          echo "hermes-desktop-remote: dashboard authentication did not become ready" >&2
          exit 1
        fi

        export HERMES_DESKTOP_REMOTE_URL="http://127.0.0.1:${toString cfg.localPort}"
        export HERMES_DESKTOP_REMOTE_TOKEN="$token"
        rc=0
        ${desktopPackage}/bin/hermes-desktop "$@" || rc=$?
        stop_tunnel
        exit "$rc"
      '';
      desktopItem = pkgs.makeDesktopItem {
        name = "hermes-desktop-remote";
        desktopName = "Hermes Desktop";
        comment = "Hermes Agent desktop client";
        exec = "${launcher}/bin/hermes-desktop-remote";
        icon = "${desktopPackage}/share/hermes-desktop/dist/hermes.png";
        categories = [
          "Network"
          "Chat"
        ];
      };
    in
    {
      options.services.hermes-remote = {
        enable = lib.mkEnableOption "remote Hermes desktop client";
        host = lib.mkOption {
          type = lib.types.str;
          description = "SSH host that runs the Hermes dashboard";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "SSH user that owns the Hermes dashboard token";
        };
        localPort = lib.mkOption {
          type = lib.types.port;
          default = 23100;
          description = "Client loopback port for the Hermes dashboard tunnel";
        };
        remotePort = lib.mkOption {
          type = lib.types.port;
          default = 22100;
          description = "Server loopback port for the Hermes dashboard";
        };
        extraSshOptions = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional arguments for the Hermes SSH connections";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          launcher
          desktopItem
        ];

        systemd.user.services.hermes-remote-tunnel = {
          description = "Hermes dashboard SSH tunnel";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            ExecStart = lib.concatStringsSep " " [
              "${pkgs.openssh}/bin/ssh"
              sshOptionsString
              "-N"
              "-L"
              "127.0.0.1:${toString cfg.localPort}:127.0.0.1:${toString cfg.remotePort}"
              destination
            ];
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
    };
}
