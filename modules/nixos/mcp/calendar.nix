_: {
  flake.modules.nixos.mcpCalendar =
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
      listenPort = 8765;
      vars = config.clan.core.vars.generators.calendar-mcp;
    in
    {
      clan.core.vars.generators.calendar-mcp = {
        prompts.username = {
          description = "OpenCloud CalDAV username";
          persist = true;
        };
        prompts.password = {
          description = "OpenCloud CalDAV password";
          type = "hidden";
          persist = true;
        };
        files = {
          username.secret = true;
          password.secret = true;
          token.secret = true;
        };
        runtimeInputs = [ pkgs.openssl ];
        script = ''
          cp "$prompts/username" "$out/username"
          cp "$prompts/password" "$out/password"
          openssl rand -hex 32 > "$out/token"
        '';
      };

      services.mcpGateway.servers.calendar = {
        url = "http://127.0.0.1:${toString listenPort}/mcp";
        tokenFile = vars.files.token.path;
        approvalTools = [
          "create_event"
          "delete_event"
          "update_event"
        ];
      };

      systemd.services.calendar-mcp = {
        description = "CalDAV MCP server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          CALDAV_URL = "https://opencloud.${flake-self.domains.local}/caldav/";
          CALENDAR_MCP_HOST = "127.0.0.1";
          CALENDAR_MCP_PORT = toString listenPort;
        };
        serviceConfig = {
          DynamicUser = true;
          LoadCredential = [
            "username:${vars.files.username.path}"
            "password:${vars.files.password.path}"
            "token:${vars.files.token.path}"
          ];
          ExecStart = pkgs.writeShellScript "calendar-mcp-start" ''
            export CALDAV_USERNAME_FILE="$CREDENTIALS_DIRECTORY/username"
            export CALDAV_PASSWORD_FILE="$CREDENTIALS_DIRECTORY/password"
            export CALENDAR_MCP_TOKEN_FILE="$CREDENTIALS_DIRECTORY/token"
            exec ${pkgs.local.calendar-mcp}/bin/calendar-mcp
          '';
          Restart = "on-failure";
          RestartSec = 5;

          CapabilityBoundingSet = "";
          IPAddressAllow = [
            "127.0.0.0/8"
            "::1/128"
            "${flake-self.hosts.nixbox.lan}/32"
            "${config.nixfiles.agentVms.hermes.hostIp}/32"
            "${config.nixfiles.agentVms.hermes.dns}/32"
          ];
          IPAddressDeny = "any";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
            "~@resources"
          ];
          UMask = "0077";
        };
      };

    };
}
