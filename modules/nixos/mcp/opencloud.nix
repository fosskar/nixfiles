_: {
  # two gateway servers, calendar (radicale through opencloud's /caldav/) and
  # opencloud (files, read-only), log in per sandbox with that sandbox's
  # opencloud account; fencr gives each sandbox its own backend process.
  # radicale map shares show up in the account they are shared with
  flake.modules.nixos.mcpOpencloud =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.nixfiles.mcpOpencloud) accounts;
      opencloudUrl = "https://opencloud.${flake-self.domains.local}";
      generatorOf = account: "opencloud-mcp-${account}";
    in
    {
      options.nixfiles.mcpOpencloud.accounts = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          hermes = "simon";
        };
        description = "opencloud account per fencr sandbox; the account names the vars generator holding its login.";
      };

      config = {
        clan.core.vars.generators = lib.mapAttrs' (
          _: account:
          lib.nameValuePair (generatorOf account) {
            prompts.username = {
              description = "OpenCloud username of the ${account} account";
              persist = true;
            };
            prompts.app-token = {
              description = "OpenCloud app token of the ${account} account";
              type = "hidden";
              persist = true;
            };
            files = {
              username.secret = true;
              app-token.secret = true;
            };
            script = ''
              cp "$prompts/username" "$out/username"
              cp "$prompts/app-token" "$out/app-token"
            '';
          }
        ) accounts;

        fencr.sandboxes = lib.mapAttrs (
          _: account:
          let
            files = config.clan.core.vars.generators.${generatorOf account}.files;
            credentials = {
              username = files.username.path;
              app-token = files.app-token.path;
            };
          in
          {
            mcp.credentials = {
              calendar = credentials;
              opencloud = credentials;
            };
          }
        ) accounts;

        fencr.mcpGateway.servers = {
          calendar = {
            command = [
              "${pkgs.writeShellScript "calendar-mcp-start" ''
                export CALDAV_USERNAME_FILE="$CREDENTIALS_DIRECTORY/username"
                export CALDAV_PASSWORD_FILE="$CREDENTIALS_DIRECTORY/app-token"
                exec ${lib.getExe pkgs.local.calendar-mcp}
              ''}"
            ];
            outbound = [ "${flake-self.hosts.nixbox.lan}/32" ];
          };
          opencloud = {
            command = [
              "${pkgs.writeShellScript "opencloud-mcp-start" ''
                OPENCLOUD_USER=$(<"$CREDENTIALS_DIRECTORY/username")
                OPENCLOUD_APP_TOKEN=$(<"$CREDENTIALS_DIRECTORY/app-token")
                export OPENCLOUD_USER OPENCLOUD_APP_TOKEN
                exec ${lib.getExe pkgs.local.opencloud-mcp}
              ''}"
            ];
            outbound = [ "${flake-self.hosts.nixbox.lan}/32" ];
          };
        };

        systemd.services = {
          "fencr-mcp-backend-calendar@".environment.CALDAV_URL = "${opencloudUrl}/caldav/";
          "fencr-mcp-backend-opencloud@".environment = {
            OPENCLOUD_URL = opencloudUrl;
            OPENCLOUD_MCP_READ_ONLY = "true";
          };
        };
      };
    };
}
