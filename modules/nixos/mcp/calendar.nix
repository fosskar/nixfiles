_: {
  flake.modules.nixos.mcpCalendar =
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
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
        };
        script = ''
          cp "$prompts/username" "$out/username"
          cp "$prompts/password" "$out/password"
        '';
      };

      # fencr runs it once per sandbox session, on a socket only its gateway reaches
      fencr.mcpGateway.servers.calendar.command = [
        "${pkgs.writeShellScript "calendar-mcp-start" ''
          export CALDAV_USERNAME_FILE="$CREDENTIALS_DIRECTORY/username"
          export CALDAV_PASSWORD_FILE="$CREDENTIALS_DIRECTORY/password"
          exec ${pkgs.local.calendar-mcp}/bin/calendar-mcp
        ''}"
      ];

      systemd.services."fencr-mcp-backend-calendar@" = {
        environment.CALDAV_URL = "https://opencloud.${flake-self.domains.local}/caldav/";
        serviceConfig = {
          LoadCredential = [
            "username:${vars.files.username.path}"
            "password:${vars.files.password.path}"
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
    };
}
