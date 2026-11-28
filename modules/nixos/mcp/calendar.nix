_: {
  # one gateway server per caldav account, calendar-<account>: an agent sees
  # only the accounts its mcp.allow names. shared calendars (radicale map
  # shares) show up in the account they are shared with
  flake.modules.nixos.mcpCalendar =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.nixfiles.mcpCalendar) accounts;
      perAccount = f: lib.listToAttrs (map f accounts);
      vars = account: config.clan.core.vars.generators."calendar-mcp-${account}";
    in
    {
      options.nixfiles.mcpCalendar.accounts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "simon"
          "hermina"
        ];
        description = "caldav accounts, each served as calendar-<account> with its own opencloud login.";
      };

      config = {
        clan.core.vars.generators = perAccount (account: {
          name = "calendar-mcp-${account}";
          value = {
            prompts.username = {
              description = "OpenCloud username of the ${account} calendar account";
              persist = true;
            };
            prompts.password = {
              description = "OpenCloud app token of the ${account} calendar account";
              type = "hidden";
              persist = true;
            };
            files = {
              username.secret = true;
              password.secret = true;
            };
            script = ''
              cp "$prompts/username" "$out/username"
              cp "$prompts/password" "$out/password"
            '';
          };
        });

        # fencr runs it once per sandbox session, on a socket only its gateway reaches
        fencr.mcpGateway.servers = perAccount (account: {
          name = "calendar-${account}";
          value.command = [
            "${pkgs.writeShellScript "calendar-mcp-${account}-start" ''
              export CALDAV_USERNAME_FILE="$CREDENTIALS_DIRECTORY/username"
              export CALDAV_PASSWORD_FILE="$CREDENTIALS_DIRECTORY/password"
              exec ${lib.getExe pkgs.local.calendar-mcp}
            ''}"
          ];
        });

        systemd.services = perAccount (account: {
          name = "fencr-mcp-backend-calendar-${account}@";
          value = {
            environment.CALDAV_URL = "https://opencloud.${flake-self.domains.local}/caldav/";
            serviceConfig = {
              LoadCredential = [
                "username:${(vars account).files.username.path}"
                "password:${(vars account).files.password.path}"
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
        });
      };
    };
}
