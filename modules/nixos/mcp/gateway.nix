_: {
  flake.modules.nixos.mcpGateway =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.mcpGateway;
      listenPort = cfg.port;
      localHost = "mcp.${flake-self.domains.local}";
      vars = config.clan.core.vars.generators.mcp-gateway;
      gatewayConfig = pkgs.writeText "mcp-gateway.json" (
        builtins.toJSON {
          servers = lib.mapAttrs (name: server: {
            inherit (server) url;
            approval_tools = server.approvalTools;
            token_credential = "downstream-${name}";
          }) cfg.servers;
        }
      );
    in
    {
      options.services.mcpGateway.port = lib.mkOption {
        type = lib.types.port;
        default = 8764;
        description = "gateway listen port; consumers use it to reach the gateway and open firewall paths.";
      };

      options.services.mcpGateway.servers = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              url = lib.mkOption { type = lib.types.str; };
              tokenFile = lib.mkOption { type = lib.types.str; };
              approvalTools = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          }
        );
        default = { };
      };

      config = {
        assertions = [
          {
            assertion = cfg.servers != { };
            message = "mcpGateway requires at least one downstream MCP server";
          }
        ];

        clan.core.vars.generators.mcp-gateway = {
          files = {
            token.secret = true;
            "token.env".secret = true;
          };
          runtimeInputs = [ pkgs.openssl ];
          script = ''
            openssl rand -hex 32 > "$out/token"
            printf 'MCP_GATEWAY_TOKEN=%s\n' "$(cat "$out/token")" > "$out/token.env"
          '';
        };

        systemd.services.mcp-gateway = {
          description = "MCP gateway for host integrations";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network-online.target"
          ]
          ++ map (name: "${name}-mcp.service") (builtins.attrNames cfg.servers);
          wants = [
            "network-online.target"
          ]
          ++ map (name: "${name}-mcp.service") (builtins.attrNames cfg.servers);
          environment = {
            MCP_GATEWAY_CONFIG = gatewayConfig;
            MCP_GATEWAY_HOST = "0.0.0.0";
            MCP_GATEWAY_PORT = toString listenPort;
          };
          serviceConfig = {
            DynamicUser = true;
            LoadCredential = [
              "token:${vars.files.token.path}"
            ]
            ++ lib.mapAttrsToList (name: server: "downstream-${name}:${server.tokenFile}") cfg.servers;
            ExecStart = pkgs.writeShellScript "mcp-gateway-start" ''
              export MCP_GATEWAY_TOKEN_FILE="$CREDENTIALS_DIRECTORY/token"
              exec ${pkgs.local.mcp-gateway}/bin/mcp-gateway
            '';
            Restart = "on-failure";
            RestartSec = 5;

            CapabilityBoundingSet = "";
            IPAddressAllow = [
              "127.0.0.0/8"
              "::1/128"
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
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy 127.0.0.1:${toString listenPort}
        '';
      };
    };
}
