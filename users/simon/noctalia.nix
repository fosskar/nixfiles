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
}
