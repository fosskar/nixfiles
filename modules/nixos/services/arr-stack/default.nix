{
  flake.modules.nixos.arrStack =
    { config, lib, ... }:
    let
      mediaRoot = "/tank/media";
      autheliaEnabled = config.services.authelia.instances.main.enable or false;
    in
    {
      config = {
        users.groups.media = { };

        systemd.tmpfiles.rules = [
          "d ${mediaRoot}/books 0775 root media -"
          "d ${mediaRoot}/movies 0775 root media -"
          "d ${mediaRoot}/music 0775 root media -"
          "d ${mediaRoot}/podcasts 0775 root media -"
          "d ${mediaRoot}/tv 0775 root media -"
          "d ${mediaRoot}/downloads 0775 root media -"
          "d ${mediaRoot}/downloads/incomplete 0775 root media -"
          "d ${mediaRoot}/downloads/complete 0775 root media -"
        ];

        services.authelia.instances.main.settings.access_control.rules = lib.mkIf autheliaEnabled (
          lib.mkBefore [
            {
              domain = [
                "sonarr.*"
                "radarr.*"
                "prowlarr.*"
                "bazarr.*"
                "sabnzbd.*"
              ];
              policy = "bypass";
              resources = [
                "^/api.*"
                "^/feed.*"
              ];
            }
            {
              domain = [
                "sonarr.*"
                "radarr.*"
                "prowlarr.*"
                "bazarr.*"
                "sabnzbd.*"
              ];
              subject = [ "group:admin" ];
              policy = "one_factor";
            }
            {
              domain = [
                "sonarr.*"
                "radarr.*"
                "prowlarr.*"
                "bazarr.*"
                "sabnzbd.*"
              ];
              policy = "deny";
            }
          ]
        );
      };
    };
}
