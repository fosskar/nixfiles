_: {
  # the secrets behind the settings below; import on hosts whose users get
  # homeManager.noctalia
  flake.modules.nixos.noctalia =
    { pkgs, ... }:
    {
      # master key for noctalia private storage (clipboard history, calendar cache);
      # noctalia requires exactly 64 lowercase hex chars and never rotates it
      clan.core.vars.generators.noctalia-storage = {
        files.key.owner = "simon";
        runtimeInputs = [ pkgs.openssl ];
        script = ''
          openssl rand -hex 32 > "$out/key"
        '';
      };

      # caldav password for the noctalia opencloud calendar account
      clan.core.vars.generators.noctalia-caldav = {
        files.password.owner = "simon";
        prompts.password = {
          type = "hidden";
          persist = true;
          description = "opencloud caldav password for noctalia";
        };
      };
    };

  flake.modules.homeManager.noctalia =
    { osConfig, self, ... }:
    {
      programs.noctalia.settings = {
        storage = {
          key_source = "file";
          key_file = osConfig.clan.core.vars.generators.noctalia-storage.files.key.path;
        };

        calendar.account.opencloud = {
          type = "caldav";
          provider = "custom";
          name = "opencloud";
          server_url = "https://opencloud.${self.domains.local}/caldav/";
          username = "simon";
          credential_source = "file";
          password_file = osConfig.clan.core.vars.generators.noctalia-caldav.files.password.path;
        };
      };
    };
}
