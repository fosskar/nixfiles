_: {
  # per opencloud account, one login (username + app token) on the host serves
  # two gateway servers: calendar-<account> (radicale through opencloud's
  # /caldav/) and opencloud-<account> (files, read-only). an agent reaches only
  # the accounts its mcp.allow names; radicale map shares show up in the
  # account they are shared with
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
      perAccount = f: lib.listToAttrs (lib.concatMap f accounts);
      backend = account: {
        serviceConfig = {
          LoadCredential =
            let
              vars = config.clan.core.vars.generators."opencloud-mcp-${account}";
            in
            [
              "username:${vars.files.username.path}"
              "app-token:${vars.files.app-token.path}"
            ];
          IPAddressAllow = [
            "127.0.0.53/32"
            "${flake-self.hosts.nixbox.lan}/32"
            "${builtins.head config.networking.nameservers}/32"
          ];
          IPAddressDeny = "any";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };
    in
    {
      options.nixfiles.mcpOpencloud.accounts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "simon"
          "hermina"
        ];
        description = "opencloud accounts, each served as calendar-<account> and opencloud-<account>.";
      };

      config = {
        clan.core.vars.generators = perAccount (account: [
          {
            name = "opencloud-mcp-${account}";
            value = {
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
            };
          }
        ]);

        # fencr runs each once per sandbox session, on a socket only its gateway reaches
        fencr.mcpGateway.servers = perAccount (account: [
          {
            name = "calendar-${account}";
            value.command = [
              "${pkgs.writeShellScript "calendar-mcp-${account}-start" ''
                export CALDAV_USERNAME_FILE="$CREDENTIALS_DIRECTORY/username"
                export CALDAV_PASSWORD_FILE="$CREDENTIALS_DIRECTORY/app-token"
                exec ${lib.getExe pkgs.local.calendar-mcp}
              ''}"
            ];
          }
          {
            name = "opencloud-${account}";
            value.command = [
              "${pkgs.writeShellScript "opencloud-mcp-${account}-start" ''
                OPENCLOUD_USER=$(<"$CREDENTIALS_DIRECTORY/username")
                OPENCLOUD_APP_TOKEN=$(<"$CREDENTIALS_DIRECTORY/app-token")
                export OPENCLOUD_USER OPENCLOUD_APP_TOKEN
                exec ${lib.getExe pkgs.local.opencloud-mcp}
              ''}"
            ];
          }
        ]);

        systemd.services = perAccount (account: [
          {
            name = "fencr-mcp-backend-calendar-${account}@";
            value = lib.recursiveUpdate (backend account) {
              environment.CALDAV_URL = "${opencloudUrl}/caldav/";
            };
          }
          {
            name = "fencr-mcp-backend-opencloud-${account}@";
            value = lib.recursiveUpdate (backend account) {
              environment = {
                OPENCLOUD_URL = opencloudUrl;
                OPENCLOUD_MCP_READ_ONLY = "true";
              };
            };
          }
        ]);
      };
    };
}
