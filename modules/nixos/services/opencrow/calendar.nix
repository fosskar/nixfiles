{
  flake.modules.nixos.opencrow =
    {
      flake-self,
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      micsSkills = inputs.mics-skills.packages.${pkgs.stdenv.hostPlatform.system};

      vdirsyncerConfig = pkgs.writeText "opencrow-vdirsyncer-config" ''
        [general]
        status_path = "/var/lib/opencrow/calendars/.status/"

        [pair calendar]
        a = "opencloud"
        b = "local"
        collections = ["from a"]
        metadata = ["displayname", "color"]

        [storage opencloud]
        type = "caldav"
        url = "https://opencloud.${flake-self.domains.local}/"
        username = "simon"
        password.fetch = ["command", "cat", "/run/credentials/opencrow.service/opencloud-caldav-token"]

        [storage local]
        type = "filesystem"
        path = "/var/lib/opencrow/calendars/collections/"
        fileext = ".ics"
      '';
    in
    {
      clan.core.vars.generators.opencrow-calendar = {
        files."opencloud-caldav-token" = { };
        prompts.opencloud-caldav-token = {
          description = "OpenCloud CalDAV app token for simon (OpenCloud -> Calendar -> generate token)";
          type = "hidden";
          persist = true;
        };
        script = ''
          cp "$prompts/opencloud-caldav-token" "$out/opencloud-caldav-token"
        '';
      };

      services.opencrow = {
        environment = {
          VDIRSYNCER_CONFIG = "${vdirsyncerConfig}";
          CALENDAR_DIR = "/var/lib/opencrow/calendars/collections";
        };

        credentialFiles."opencloud-caldav-token" =
          config.clan.core.vars.generators.opencrow-calendar.files."opencloud-caldav-token".path;

        skills.calendar = "${micsSkills.calendar-cli}/share/skills/calendar-cli";

        extraPackages = [
          micsSkills.calendar-cli
          pkgs.vdirsyncer
        ];
      };

      containers.opencrow.config.systemd.tmpfiles.rules = [
        "d /var/lib/opencrow/calendars 0750 opencrow opencrow -"
        "d /var/lib/opencrow/calendars/collections 0750 opencrow opencrow -"
        "d /var/lib/opencrow/calendars/.status 0750 opencrow opencrow -"
      ];
    };
}
