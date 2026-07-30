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
          # setgid: subdirs the apps create inherit group media, so UMask 0002
          # alone does not have to carry group ownership
          "d ${mediaRoot}/books 2775 root media -"
          "d ${mediaRoot}/movies 2775 root media -"
          "d ${mediaRoot}/music 2775 root media -"
          "d ${mediaRoot}/podcasts 2775 root media -"
          "d ${mediaRoot}/tv 2775 root media -"
          "d ${mediaRoot}/downloads 2775 root media -"
          "d ${mediaRoot}/downloads/incomplete 2775 root media -"
          "d ${mediaRoot}/downloads/complete 2775 root media -"
        ];

        # media consumers must not start (and write into the empty mountpoint
        # dir on the ephemeral root) unless the media mount is up. prowlarr,
        # recyclarr, and seerr only talk to APIs and stay out of this list.
        systemd.services =
          lib.genAttrs
            [
              "sonarr"
              "radarr"
              "lidarr"
              "bazarr"
              "sabnzbd"
              "jellyfin"
              "navidrome"
            ]
            (_: {
              unitConfig.RequiresMountsFor = [ mediaRoot ];
            });

        services.authelia.instances.main.settings.access_control.rules = lib.mkIf autheliaEnabled (
          lib.mkBefore [
            {
              domain = [
                "sonarr.*"
                "radarr.*"
                "lidarr.*"
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
                "lidarr.*"
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
                "lidarr.*"
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
